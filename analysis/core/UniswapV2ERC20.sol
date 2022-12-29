pragma solidity =0.5.16;

import './interfaces/IUniswapV2ERC20.sol';
import './libraries/SafeMath.sol';

contract UniswapV2ERC20 is IUniswapV2ERC20 {
    using SafeMath for uint;
		// 스마트컨트랙트에서 숫자 연산을 할 때 공통적으로 발생하는 문제는 오버플로우, 언더플로우의 위험을 SafeMath를 이용하면 예방할 수 있다. 

    string public constant name = 'Uniswap V2';
    string public constant symbol = 'UNI-V2';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
		// 지갑주소[토큰양]으로 매핑
    mapping(address => mapping(address => uint)) public allowance;
		// Owner[Spender[허용된토큰]]으로 매핑
    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;
		// owner[논스값]으로 매핑

    event Approval(address indexed owner, address indexed spender, uint value);
		// approve와 permit이 실행되었을때 이벤트 발생 (owner, spender, value)
    event Transfer(address indexed from, address indexed to, uint value);
		// transfer, transferFrom, mint, burn이 실행되었을때 이벤트 발생 (from, to, value)

    constructor() public {
        uint chainId;
	      assembly {
            chainId := chainid 
					// 대입연산자로 초기화
        } // 어셈블리를 이용하여 가스비 절약
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        ); 
				// abi로 인코딩한 후 해쉬화해서 DOMAIN_SEPARATOR에 대입
				// 이는 permit에 사용될 예정
    }

	  function _mint(address to, uint value) internal {
				// 상속할 수 있도록 internal 접근제어자 사용
				// 파라미터로 받는 주소와 보낼 토큰양
				// 토큰 발행(?)
        totalSupply = totalSupply.add(value);
				// 총량에 추가 공급량 더함 // SafeMath의 add() 함수 이용
        balanceOf[to] = balanceOf[to].add(value);
				// 잔액이 매핑되어있는 balanceOf에 추가 공급량 더함
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
				// 소각
        balanceOf[from] = balanceOf[from].sub(value);
				// 잔액이 매핑되어있는 balanceOf에서 value만큼의 값 뺌 // SafeMath의 sub() 함수 이용 
        totalSupply = totalSupply.sub(value);
				// 총량에 value 만큼의 값 뺌.
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
				// spender에게 value 값 허용해주기위해 필요 
        allowance[owner][spender] = value;
				// Owner[Spender[허용된토큰]]으로 매핑된 배열에 value값 대입
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
				// from에서 to로 value값 전송하기위해 필요
        balanceOf[from] = balanceOf[from].sub(value);
				// 전송했으니 from의 banlancOf 값 value 만큼 뺌
        balanceOf[to] = balanceOf[to].add(value);
				// to는 value 만큼 받았으니 balanceOf에 더함
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
				// msg.sender로부터 spender에게 value만큼 허용
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
				// msg.sender로부터 to에게 value 만큼 전송
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
						// uint(-1)은 uint256의 최대값을 뜻함 => 0xFF...FF
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
						// 보냈으면 허용량을 나타내는 allowance에서 value만큼의 값을 빼야함 
        }
        _transfer(from, to, value);
				// from에서 to로 value만큼 전송
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
				// 데드라인이 블록의 타임스탬프보다 크다면, 아직 유효
				// 그 반대라면 데드라인을 넘은것이므로 EXPIRED라는 에러 발생
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
				// ecrecover()에 코드와 같은 파라미터를 넣으면, 서명한 지갑의 주소가 나온다. (EIP712의 verify 함수에서 이용)
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
				// 서명한 주소가 0x00으로 초기화 되어있지 않고, 서명한주소가 owner일대 통과
				// 위의 내용이 아니라면 owner가 서명한것이 아니므로 에러 표시 
        _approve(owner, spender, value);
    }
}