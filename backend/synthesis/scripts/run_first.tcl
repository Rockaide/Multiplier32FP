# Ao longo do curso você irá adicionando comandos neste arquivo(!)




# configurações iniciais
export DESIGNS="somador" ;# put here the name of current design. Nome da pasta e do top level
export USER=ufsm00291-lima202020189;# put here YOUR user name at this machine
export COURSE=ufsm00291/ ;# put the course name "UFSM00291/" or nothing
export PROJECT_DIR=/home/${COURSE}${USER}/projetos/${DESIGNS}
export BACKEND_DIR=${PROJECT_DIR}/backend
export TECH_DIR=/home/tools/design_kits/cadence/GPDK045 ;# technology dependent
export HDL_NAME=${DESIGNS}
export VLOG_LIST="$BACKEND_DIR/synthesis/deliverables/${DESIGNS}.v"







# carregando os módulos que possibilitam executar as ferramentas
module add cdn/genus/genus211
module add cdn/xcelium/xcelium2309
module add cdn/innovus/innovus211






# Comandos relacionados ao XCELIUM
cd ${PROJECT_DIR}/frontend
### run HDL
xrun -clean -64bit -v200x -v93 ${DESIGNS}.vhd Util_package.vhd ${DESIGNS}_tb.vhd -top ${DESIGNS}_tb -access +rwc #-gui










# Comandos relacionados ao GENUS
cd ${PROJECT_DIR}/backend/synthesis/work #diretório a partir do qual a gente vai abrir a ferramenta de synthèse
## apenas o programa
genus -abort_on_error -lic_startup Genus_Synthesis -lic_startup_options Genus_Physical_Opt -log genus -overwrite #-gui
# programa e carrega script para síntese automatizada











# Para executar o INNOVUS
cd ${PROJECT_DIR}/backend/layout/work
## apenas o programa
innovus -stylus -overwrite # -no_gui






