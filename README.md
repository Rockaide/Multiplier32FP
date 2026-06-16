Repository for the implementation and verification of a 32 bits multiplier for the subjet UFSM00291 - Projeto de Sistemas Digitais Integrados (Project of Integrated Digital Systems)

Repositório para implementação e verificação de um multiplicador de 32 bits para a disciplina UFSM00291 - Projeto de Sistemas Digitais Integrados

## Ambiente de Execução

Este projeto foi estruturado para ser executado nos laboratórios do NUPEDEE ou via acesso remoto aos servidores ECOMP. O fluxo de execução (simulação, síntese lógica e física) é inteiramente automatizado através do arquivo Makefile localizado no diretório de topo do projeto. O script se encarrega de carregar os módulos necessários do CADENCE (Xcelium, Genus, Innovus).  

## Instruções de Uso

Para executar o fluxo ASIC, abra o terminal na pasta raiz do projeto e utilize o comando make seguido do alvo desejado e, opcionalmente, das variáveis de configuração.
Sintaxe Básica

Bash:
make <target> [VARIAVEL=valor]

## Variáveis de Configuração Principais

    FREQ_MHZ: Define a frequência de operação do clock alvo em MHz (Padrão: 100).

    LIB_TYPE: Define a biblioteca de operação. Opções: worst ou best (Padrão: worst).

    VECT: Define 1 para utilizar o testbench com o arquivo de vetores, ou 0 para o funcional (Padrão: 0).  

    GUI: Define 1 para abrir a interface gráfica do simulador (Xcelium) na simulação RTL.

## Comandos de Execução (Targets)

As opções abaixo cobrem os requisitos mínimos exigidos para a avaliação do fluxo.  

**EXECUTAR make setup_dirs ANTES DE QUALQUER COISA.

1. Fluxo Completo para uma Frequência Específica
Executa sequencialmente a síntese lógica, o layout, a simulação pós-layout (gerando VCD) e a análise de potência.

Bash:
make flow_full_single_config FREQ_MHZ=100 LIB_TYPE=worst VECT=1

2. Descoberta da Máxima Frequência de Operação
Automatiza o incremento da frequência na síntese lógica iterativamente até encontrar um slack negativo, retornando o circuito mais rápido possível.  

Bash:
make find_max_freq START_FREQ_SYNTH=100 FREQ_STEP_SYNTH=5

3. Obtenção de Dados para a Tabela de Resultados (Anexo A)
Estes comandos executam o fluxo de síntese (lógica ou física) e geram automaticamente os relatórios de potência sem anotação, bem como as extrações baseadas em VCD para os tempos "X" e "2X".

*Os tempos X e 2X foram obtidos através da simulação do testbench. Seus valores são automaticamente atualizados dependendo da frequência e passados para o testbench.

    Para a Síntese Lógica:

    Bash:
    make vcd_synth FREQ_MHZ=100 VECT=1

    Para a Síntese Física (Layout):
    
    Bash:
    make vcd_layout FREQ_MHZ=100 VECT=1

4. Simulação RTL (Nível HDL)
Para demonstrar o correto funcionamento do circuito e inspecionar as formas de onda.  

Bash:
make sim_rtl GUI=1

5. Limpeza do Diretório
Para remover logs, histórico e arquivos temporários da pasta work:  

Bash:
make clean

Seguindo a estrutura de diretórios do projeto, os resultados gerados pelas ferramentas podem ser encontrados nos seguintes locais:  

    Relatórios de Desempenho (Área, Timing, Potência):  

    backend/synthesis/reports/<configuração>/

    backend/layout/reports/<configuração>/

Arquivos de Saída (Netlist .v, SDF .sdf):  

        backend/synthesis/deliverables/<configuração>/

        backend/layout/deliverables/<configuração>/

**O nome das configurações seguirá o modelo <NOME DO RTL>_<TIPO DA LIVRARIA>_$<FREQUÊNCIA DA SÍNTESE>_<TEMPO DE SIMULAÇÃO>
Exemplo : multiplier32FP_worst_10_160551

Para visualizar a lista completa de comandos disponíveis diretamente no terminal, execute: make help.