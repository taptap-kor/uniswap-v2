## UNISWAP V2 CONTRACT ANALYSIS PROJECT

본 프로젝트는 Defi 시장에서 중요한 역할을 하는 UniSwap의 컨트랙트 분석과 공부를 위해 진행됩니다.

contract/core 에는 총 세가지 컨트랙트가 있습니다.

1. factory.sol
2. erc20.sol
3. pair.sol

각각의 코드는 uniswap github에서 가져온 코드이며, 개인적으로 분석하고 공부한 내용은 아래와 같이 주석으로 표기가 되어있습니다.

### 작성된 코드 중 일부
``` solidity
bytes memory bytecode = type(UniswapV2Pair).creationCode;
// ABI생성과 같이 byte코드를 생성해주는 라인
// UniswapV2Pair 컨트랙트를 넣어주면 바이트코드가 생성
// type(ContractName).creationCode => 이게 하나의 포맷임.

```
