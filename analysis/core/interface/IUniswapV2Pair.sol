// 상속받은 IUniswapV2Pair 컨트랙트 함수 분석
// UniSwap Guide Link : https://docs.uniswap.org/contracts/v2/reference/smart-contracts/pair

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

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

  function MINIMUM_LIQUIDITY() external pure returns (uint);
	// 모든 페어에 대해 '1000' 리턴 // 반올림 오류를 개선을 하고, 이론상 최소 틱사이즈를 늘리기위해 최소값을 지정.
  function factory() external view returns (address);
	// factory 주소값을 리턴
  function token0() external view returns (address);
	// 페어내에서 더 적게 분류된 토큰의 주소값을 리턴
  function token1() external view returns (address);
	// 페어내에서 더 많이 분류된 토큰의 주소값을 리턴
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  // 페어에 대한 상호작용이 일어난 시점 직전의 블록타임스탬프를 찍어주고 0,1의 잔여량을 리턴. 
	function price0CumulativeLast() external view returns (uint);
  // 오라클 관련 : https://docs.uniswap.org/contracts/v2/concepts/core-concepts/oracles
	function price1CumulativeLast() external view returns (uint);
  // 오라클 관련 : https://docs.uniswap.org/contracts/v2/concepts/core-concepts/oracles
	function kLast() external view returns (uint);
	// CPMM(Constant Product Market Maker)을 위해서 페어에 관련된 두 토큰의 잔여량의 곱(k)을 구한 뒤 리턴

  function mint(address to) external returns (uint liquidity);
	// pool 토큰을 생성
	// Mint, Sync, Transfer 이벤트 발생
	function burn(address to) external returns (uint amount0, uint amount1);
  // pool 토큰을 소각
	// Burn, Sync, Transfer 이벤트 발생
	function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
	// 토큰을 스왑. 일반적인 스왑의 경우 data.length는 '0' 이어야 함. (0 이라는 값은 FlashSwap에서 선불비용없이 거래할 수 있다는 뜻인 듯)

	// sync()과 skim()은 토큰 잔액에 대해 오버플로우와 같은 문제가 발생했을때 필요한 대비책으로 작용한다. 자세한 내용은 백서 참조
	// whitepaper : https://docs.uniswap.org/whitepaper.pdf
  function skim(address to) external;
	// 오버플로가 될때 철회할 수 있도록 하는 기능.
  function sync() external;
	// 토큰 페어의 균형이 비동기적으로 deflate되려 할때 회복될 수 있도록 하는 구제책.
}