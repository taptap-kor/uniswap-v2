pragma solidity =0.5.16;

import './interfaces/IUniswapV2Factory.sol';
import './UniswapV2Pair.sol';


// ###################################################################################### //
// import 하는 곳의 코드 => 임의로 가져옴

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint); 
		// createPair이 실행될때마다 이벤트 발생
		// token0은 token1보다 작아야하며 순서상 앞에 위치해야하는게 보장된다.

    function feeTo() external view returns (address); // 수수료가 모이는 주소
    function feeToSetter() external view returns (address); // feeTo 주소를 설정할 수 있는 관리자 주소
    function getPair(address tokenA, address tokenB) external view returns (address pair); // 두 토큰의 주소를 받아 두 토큰에 대한 pair 주소를 리턴 (생성되어 있지 않으면 0번 주소)
    function allPairs(uint) external view returns (address pair); // 생성되어 있다는 전제하에, n번째 페어 주소를 리턴. 없으면 0번 주소
    function allPairsLength() external view returns (uint); // 팩토리를 통해 생성된 총 페어의 개수를 리턴

    function createPair(address tokenA, address tokenB) external returns (address pair); // 두 토큰의 주소에대한 페어 주소 생성 (아직 없다는 전제하에)

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
// ###################################################################################### //


contract UniswapV2Factory is IUniswapV2Factory {
    address public feeTo; // 요금을 부과하는 대상
    address public feeToSetter; // 

    mapping(address => mapping(address => address)) public getPair; // 이중매핑 addr[addr[addr]]
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES'); 
        // A와 B가 같을경우 오류 발생 (Identical addr: 동일한 주소)
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA); 
        // 무조건 token0가 token1의 양보다 적은 순서로 배치되어야 하기때문에 필요한 라인 
        // 참고 : https://docs.uniswap.org/contracts/v2/reference/smart-contracts/factory#paircreated
        // A가 작을경우 0번에 A, 1번에 B
        // B가 작을경우 1번에 B, 2번에 A 
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS'); // 0x00이면 에러표시
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        // 0,1번의 토큰페어가 이미 존재하면 에러표시
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        // ABI생성과 같이 byte코드를 생성해주는 라인
        // UniswapV2Pair 컨트랙트를 넣어주면 바이트코드가 생성
        // type(ContractName).creationCode => 이게 하나의 포맷임.
        // 참고 (링크내의 "Creation Bytecode" 챕터) : https://medium.com/authereum/bytecode-and-init-code-and-runtime-code-oh-my-7bcd89065904
        bytes32 salt = keccak256(abi.encodePacked(token0, token1)); // 암호화에 필요한 salt를 token0와 token1을 이용해 생성
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
            // ":=" => 오른쪽 식을 왼쪽에 대입한다(대입연산자) => 어셈블리내에서는 이걸 사용해야하는 듯 하다.
            // create2 => 배포전에 컨트랙트를 미리 계산할 수 있다. 즉 두 토큰과 관련된 페어주소를 뽑아낸다.
            // create2 참고자료 및 사용방법 : https://solidity-by-example.org/app/create2/
        }
        IUniswapV2Pair(pair).initialize(token0, token1); // pair 컨트랙트내에 있는 token0,1 에 전역변수로 초기화해두는 작업
        getPair[token0][token1] = pair; // 두 토큰에 매칭되는 페어 주소 기입.
        getPair[token1][token0] = pair; // 0와 1은 지정된 토큰의 개수 차이로 지정되는 순서이므로, 역방향 매핑작업이 필요
        allPairs.push(pair); // allPairs 배열에는 push로 대입
        emit PairCreated(token0, token1, pair, allPairs.length); // 페어가 생성된것을 이벤트로 방출
    }

    function setFeeTo(address _feeTo) external { 
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
        // 수수료 받는 지갑을 설정할 수 있는 함수
        // 이 권한을 가진 feeToSetter일 경우에만 사용 가능
    } 


    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
        // setFeeTo 함수를 사용할 수 있는 관리자 지갑을 변경할 수 있는 함수
        // 관리자만이 사용할 수 있다.
}
    } 
