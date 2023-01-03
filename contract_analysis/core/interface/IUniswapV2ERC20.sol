// 상속받은 IUniswapV2ERC20 컨트랙트 함수 분석
// https://docs.uniswap.org/contracts/v2/reference/smart-contracts/Pair-ERC-20

interface IUniswapV2ERC20 {
  event Approval(address indexed owner, address indexed spender, uint value);
	// approve와 permit이 실행되었을때 이벤트 발생 (owner, spender, value)
  event Transfer(address indexed from, address indexed to, uint value);
	// transfer, transferFrom, mint, burn이 실행되었을때 이벤트 발생 (from, to, value)
  function name() external pure returns (string memory);
	// 생성할 토큰 페어의 이름을 출력
	// 하지만 항상 'Uniswap V2'으로 출력이 되는데, 페어의 이름은 중요하지 않다.
	// 만약 유저들이 직접 이름을 명시할 수 있다고 가정하면, 이런 경우가 생길 수 있다.
	// ETH-DAI라고 명시된 컨트랙트를 이용해야한다고 가정해보자.
	// 사기꾼들은 이를 이름만 ETH-DAI지 실제로는 다른 토큰페어를 만들어 컨트랙트만 게시해놓을 수 있다.
	// 이럴경우, 페어에 관한 컨트랙트주소를 확인하지 않는 유저들은 가치없는 토큰을 스왑할 가능성이 크다.
	// 참고 : https://stackoverflow.com/questions/71186038/uniswap-v2-erc20-token-solidity-code-are-token-names-hard-coded

  function symbol() external pure returns (string memory);
	// 모든 페어에 대해 UNI-V2 가 출력된다. 이유는 위 name과 같다.
  function decimals() external pure returns (uint8);
	// 모든 페어에 대해 18이 출력된다. 소수점 아래 수 18자리까지인 듯하다.
  function totalSupply() external view returns (uint);
	// 만들고자하는 페어에 관한 토큰(ERC20)의 총 발행량을 출력
  function balanceOf(address owner) external view returns (uint);
	// Owner가 가지고 있는 페어에 관한 토큰(ERC20)양
  function allowance(address owner, address spender) external view returns (uint);
	// spender가 transferFrom을 통해 보낼 수 있는 유동성 토큰양을 리턴
  function approve(address spender, uint value) external returns (bool);
	// 호출한 msg.sender가 spender에게 value값 만큼 허용  
	// Approval 이벤트 발생
  function transfer(address to, uint value) external returns (bool);
	// 호출한 msg.sender가 to 주소에 value값 만큼 전송
	// Transfer 이벤트 발생
  function transferFrom(address from, address to, uint value) external returns (bool);
	// from으로부터 to로 토큰 전송
	// Transfer 이벤트 발생
  function DOMAIN_SEPARATOR() external view returns (bytes32);
	// permit 함수에 사용할 도메인 구분기호를 리턴
  function PERMIT_TYPEHASH() external pure returns (bytes32);
	// permit 함수에 사용할 typehash를 리턴
  function nonces(address owner) external view returns (uint);
	// permit 함수에 사용할 현재 논스값을 리턴
  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
	// signature(서명)을 통해 approval이 승인된 spender에게 allowance양을 지정
	// Approval 이벤트 발생
}