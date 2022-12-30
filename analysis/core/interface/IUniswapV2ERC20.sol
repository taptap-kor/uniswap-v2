// 상속받은 IUniswapV2ERC20 컨트랙트 함수 분석
// https://docs.uniswap.org/contracts/v2/reference/smart-contracts/Pair-ERC-20

pragma solidity >=0.5.0;

interface IUniswapV2ERC20 {
  event Approval(address indexed owner, address indexed spender, uint value);
	// approve와 permit이 실행되었을때 이벤트 발생 (owner, spender, value)
  event Transfer(address indexed from, address indexed to, uint value);
	// transfer, transferFrom, mint, burn이 실행되었을때 이벤트 발생 (from, to, value)
  function name() external pure returns (string memory);
	// Returns 'Uniswap V2' for all pairs.
  function symbol() external pure returns (string memory);
	// Returns UNI-V2 for all pairs.
  function decimals() external pure returns (uint8);
	// Returns 18 for all pairs.
  function totalSupply() external view returns (uint);
	// 페어에 관한 토큰 총개수를 리턴
  function balanceOf(address owner) external view returns (uint);
	// 파라미터로 들어온 주소에 들어있는 토큰 개수 리턴
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