pragma solidity =0.5.16;

import './interfaces/IUniswapV2Pair.sol';
import './UniswapV2ERC20.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/IERC20.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Callee.sol';

contract UniswapV2Pair is IUniswapV2Pair, UniswapV2ERC20 {
    using SafeMath  for uint;
    using UQ112x112 for uint224;
		// uint112에서 112 만큼 이동시켜 uint224로 변환하게 하기위해 필요
		// 오버플로우 발생 x 
		// 함수 설명 : https://stackoverflow.com/questions/72644712/math-in-uniswap-uq112xuq112-library

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; 
		// reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

		// modifier(함수변경자) 이해하기
		// " _; " 위치가 밑에 생성된 function들이 들어갈 위치이며, 그 앞뒤로 unlocked가 0이 되었다 1이 되었다 하는것이다.
		// 즉 함수가 실행되기 전까지는 lock, 실행 이후는 unlock시키는 코드인 듯 하다. 

         // 이어서

		function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }
		// 잔여량 받아서 지역변수 형태의 _reserve0,1 에 초기화

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
				// 0.5.0 버전이후 call()을 사용하면, 호출의 성공여부인 bool과 함수의 리턴값을 bytes 형태로 받아올수 있음.
				// 성공여부를 success에 저장하고, 함수의 리턴값을 data에 저장.
				// 함수가 성공했다면 별다른 리턴값없이 data에 아무것도 안담기게됨.
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
				// 윗줄에서 success가 true이고, data에 아무것도 안들어 있어야 성공임.(data에 뭔가 들어있다면 함수가 실패하여 실패사유 등이 반환되었다는 뜻)
    }


		// 이벤트는 상속받은 IUniswapV2Pair 컨트랙트 내용과 동일
		event Mint(address indexed sender, uint amount0, uint amount1);
		// mint 함수를 통해 유동성토큰 발행시마다 이벤트 발생
	  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
		// burn 함수를 통해 유동성토큰 소각시마다 이벤트 발생
	  event Swap(
	      address indexed sender,
	      uint amount0In,
	      uint amount1In,
	      uint amount0Out,
	      uint amount1Out,
	      address indexed to
	  );
		// swap 함수를 통해 스왑할때마다 이벤트 발생
	  event Sync(uint112 reserve0, uint112 reserve1);
		// mint, burn, swap, sync 함수들을 통해서 잔여량이 업데이트될때마다 이벤트 발생

    constructor() public {
        factory = msg.sender;
    }
		// 컨트랙트 호출자가 factory 주소로 지정

		// factory 컨트랙트를 살펴보면, IUniswapV2Pair(pair).initialize(token0, token1); 와 같이 호출해서, 한번 초기화시킴.
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
				// 바로 위 constructor에서 factory에 msg.sender를 대입했고 factory에서 이 함수를 호출하므로, factory 호출자와 동일한 주소여야 함.
        token0 = _token0; 
        token1 = _token1;
				// 전역변수에 초기화
				// token0,1은 주소값이 들어간 것임을 기억.
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'UniswapV2: OVERFLOW');
				// uint112(-1)은 uint112에서 가장 큰 0xff...f이므로 이걸 넘어가면 오버플로 에러가 발생되어야함.
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired // 오버플로가 필요함(?)
				// 이전 블록스탬프에서부터 현재 블록스탬프까지의 시간차를 구함

				// 이 내용은 https://ethereum.org/en/developers/tutorials/uniswap-v2-annotated-code/ 여기 참고하는게 좋음
				// 계산해야할 내용이 있음
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }	// 타임스탬프간의 token 평균가격을 구해야함 
			
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
				// 가장 최신화된 잔액을 reserve0,1에 대입
        blockTimestampLast = blockTimestamp;
				// 이전 블록스탬프에 밀어넣기 
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
				// feeTo는 수수료를 받는 지갑주소 (관리자쪽)
        feeOn = feeTo != address(0);
				// 지갑주소(feeTo)가 0번 주소가 아닐때 feeOn이 활성화
        uint _kLast = kLast; // gas savings
        if (feeOn) { // feeOn이 ON/OFF 됨
            if (_kLast != 0) { // k상수가 오류등으로 0이 아닐때 (즉 reserve0, reserve1이 존재할때)
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
								// root(k) = k^1/2 // 현 시점 잔여량에 대한 k의 제곱근
                uint rootKLast = Math.sqrt(_kLast);
								// 이전 k의 제곱근
                if (rootK > rootKLast) {
										// 제곱근형태로 비교하는건, 음수형태인지 확인하려는 건가? 허수발생을 막으려고?
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
										// totalsupply*(root(k)-root(k_last))
                    uint denominator = rootK.mul(5).add(rootKLast);
										// 5*root(k)+root(k_last)
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }
		// _mintFee 존재의의 : Uniswap 2.0에서 거래자는 시장을 사용하기 위해 0.30%의 수수료를 지불합니다. 
		// 대부분의 수수료(거래의 0.25%)는 항상 유동성 공급자에게 전달됩니다. 
		// 나머지 0.05%는 유동성 공급자 또는 프로토콜 수수료로 공장에서 지정한 주소로 갈 수 있으며 
		// Uniswap의 개발 노력에 대한 비용을 지불합니다.


    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint liquidity) {
				// 선언부에 lock이 있는데 이는 modifier lock을 설정한 상황에 따라 실행시키는것을 적용한다
				// 즉 여러사람이 컨트랙트를 이용할때 이 함수를 이용하는 상황에 영향을 주지 못하도록 lock 시킴 
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
				// initialize()에서 초기화된 tokenA,B 에서 작은쪽의 주소값에서의 토큰양
        uint balance1 = IERC20(token1).balanceOf(address(this));
				// initialize()에서 초기화된 tokenA,B 에서 큰쪽의 주소값에서의 토큰양
        uint amount0 = balance0.sub(_reserve0);
				// 현재 토큰양을 뜻하는 balance0에서, 페어에 대한 상호작용이 일어나기 전인 reserve0 값을 뺌.
				// 즉 새로 공급(입금?)된 토큰양이지 않을까
				// swap, mint, burn 이 실행될때만 reserve값이 업데이트되므로, 유동성공급을 위해 들어온 돈은 업데이트가 안되었을것이다.
        uint amount1 = balance1.sub(_reserve1);
				// 현재 토큰양을 뜻하는 balance1에서, 페어에 대한 상호작용이 일어나기 전인 reserve1 값을 뺌.
				

        bool feeOn = _mintFee(_reserve0, _reserve1);
				// _mintFee를 통해 feeOn을 on/off 한다.
				// 수수료를 계산하고, 그에 따라 유동성 토큰을 발행 

				
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) { 
						// 첫 입금일경우
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
						// 첫 입금 시 두 토큰의 상대적 가치를 모르기 때문에, 
						// 두 토큰에서 동일한 가치를 제공한다고 가정하고 금액을 곱하고 제곱근을 취한것을 유동성으로 지정.
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
						// MINIMUM_LIQUIDITY만큼의 양을 0번 주소에 발행한다. 즉 영원히 lock 시키는 것이다.
        } else {
						// 첫입금이 아닐경우
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
						// 유동성은 다음과 같이 계산한다. 
						// 식을 보면 (amount0/_reserve)(컨트랙트내의 balance 중에서 새로 공급한 토큰양)*_totalsupply 인데, 전
						// 전체 발행량중 이번에 입금한 amount0의 비율이 얼마나되냐 이 뜻인듯하다.
        }
        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);
				// liquidity가 문제없다면 발행

        _update(balance0, balance1, _reserve0, _reserve1);
				// 토큰양 업데이트
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
				// 수수료 정산까지 마쳤다면 CPMM의 k값 구하기
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
				// liquidity가 출금되거나 적절한 토큰양을 소각해야할 때 필요
				// 선언부에 lock이 있는데 이는 modifier lock을 설정한 상황에 따라 실행시키는것을 적용한것
				// 즉 여러사람이 컨트랙트를 이용할때 이 함수를 이용하는 상황에 영향을 주지 못하도록 lock 시킴 

        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
				// mint 내용과 동일
        uint liquidity = balanceOf[address(this)];
				
        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
				// 소각할 양 (즉 출금예정인 양, 또는 특별한 이유로 소각할양)
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
				// 유동성 제공자는 두토큰과 동일한 가치를 받는다.
				// 이렇게하면 환율이 바뀌지 않는다.

        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
				// 이전 두 함수와 똑같이 lock modifier가 연결되어있음
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');
				// amount0,1out의 양수여부를 판단하고, 요구하는게 풀에 있는 유동량보다 많은지 확인한다. (유동량 보다 많이 줄수는 없으므로)

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
				// 풀에 존재하는 토큰을 스왑하는 주체에게 전달
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
				// 왜 두쪽다 to에게 전달하는지 이해가 안간다.
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
				// 현재 잔액 확인
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
				// 0.3%의 수수료를 떼기위한 코드
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
        }
				// 온전성 검사. 진행중에 누락된 양이 있는지 파악하기 위해필요
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}