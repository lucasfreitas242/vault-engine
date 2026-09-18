# Contexto do Projeto e Diretrizes do Agente: vaults-engine

## 1. Stack & Ferramentas
- Framework: Foundry (Forge, Cast, Anvil)
- Linguagem: Solidity (versão padrão: ^0.8.20 ou superior)
- Padrões de Token: ERC-4626 (Tokenized Vaults), ERC-20
- Bibliotecas Permitidas: OpenZeppelin Contracts, Solmate (avaliar trade-offs de gas vs segurança)

## 2. Padrões de Arquitetura & Smart Contracts
- Filosofia: Modularidade, minimização de superfície de ataque e otimização severa de gas.
- Padrão de Vaults: Toda implementação deve seguir estritamente o padrão ERC-4626 para depósitos, saques e cálculo de cotas (shares/assets).
- Regras de Ouro:
  - Padrão Checks-Effects-Interactions (CEI) rigoroso em todas as funções externas que alteram estado ou transferem fundos.
  - Uso explícito de `nonReentrant` em fluxos com saques e chamadas externas.
  - Tratar inflação de share/donation attacks (usar virtual shares/assets ou primeiro depósito bloqueado).
  - Uso de tipos explícitos (`uint256` em vez de tipos genéricos/inferidos).

## 3. Comandos de Terminal & Loop de Validação (Foundry)
- Compilar: `forge build`
- Rodar Testes Unitários: `forge test -vvv`
- Rodar Testes de Fuzzing/Invariantes: `forge test --match-test testFuzz -vvv`
- Análise de Gas: `forge snapshot`
- Formatação: `forge fmt --check`
- Regra de Execução: Após qualquer alteração em arquivos `.sol`, execute `forge test -vvv`. A tarefa só é considerada concluída se a compilação e a suíte completa de testes passarem sem avisos.

## 4. Estratégia de Testes Obrigatória
- Testes Unitários: Cobrir caminhos felizes e reentrâncias esperadas para cada função externa.
- Testes com Revert: Validar todos os `vm.expectRevert()` com Custom Errors declarados explicitamente (evitar strings de require longas para poupar gas).
- Fuzzing: Todo cálculo matemático (cálculo de yield, shares, assets e taxas) deve possuir pelo menos um teste com fuzzing aleatório (`testFuzz_*`).
- Invariant Testing: Escrever invariantes para garantir que a soma das cotas reflita a liquidez total do cofre em qualquer cenário de estresse.

## 5. Casos de Borda Críticos & Auditoria Interna
- Proteção contra Front-running / Slippage: Exigir parâmetros de `minSharesOut` e `minAssetsOut` em operações sensíveis ao tempo.
- Precisão Decimal: Manter rigor na conversão entre tokens com casas decimais diferentes (ex: USDC 6 decimais vs WETH 18 decimais).
- Manipulação de Oráculos: Nunca usar cotação direta de pools spot (AMM) sem proteção de TWAP ou oráculos descentralizados (Chainlink).

## 6. Formato de Saída (Spec-First)
Antes de criar ou alterar qualquer contrato:
1. Apresentar os eventos, structs e Custom Errors que serão adicionados.
2. Listar os cenários de ataque considerados (reentrancy, share manipulation, overflow de round).
3. Apresentar a matriz de testes necessários antes de escrever o código de produção.