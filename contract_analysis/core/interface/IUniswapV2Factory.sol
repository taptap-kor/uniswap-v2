pragma solidity >=0.5.0;

// 상속받은 IUniswapV2Factory 컨트랙트 함수 분석
// UniSwapV2 Guide Link : https://docs.uniswap.org/contracts/v2/reference/smart-contracts/factory

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