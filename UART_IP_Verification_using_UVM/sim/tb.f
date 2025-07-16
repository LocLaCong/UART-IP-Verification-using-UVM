+incdir+${UART_IP_VERIF_PATH}/sequences
+incdir+${UART_IP_VERIF_PATH}/testcases
+incdir+${UART_IP_VERIF_PATH}/testcases/register_test
+incdir+${UART_IP_VERIF_PATH}/testcases/oversampling_test
+incdir+${UART_IP_VERIF_PATH}/testcases/transmitter_test
+incdir+${UART_IP_VERIF_PATH}/testcases/receiver_test
+incdir+${UART_IP_VERIF_PATH}/testcases/full_duplex_test
+incdir+${UART_IP_VERIF_PATH}/testcases/interrupt_test
+incdir+${UART_IP_VERIF_PATH}/testcases/error_injection_test
+incdir+${UART_IP_VERIF_PATH}/testcases/error_handling_test
+incdir+${UART_IP_VERIF_PATH}/testcases/reconfig_test
+incdir+${UART_IP_VERIF_PATH}/tb
+incdir+${UART_IP_VERIF_PATH}/regmodel
+incdir+${UART_IP_VERIF_PATH}/regmodel/register

// Compilation VIP design (agent) list
-f ${UART_VIP_ROOT}/uart_vip.f
-f ${AHB_VIP_ROOT}/ahb_vip.f

// Compilation Environment
${UART_IP_VERIF_PATH}/regmodel/register/uart_register_pkg.sv
${UART_IP_VERIF_PATH}/regmodel/uart_regmodel_pkg.sv
${UART_IP_VERIF_PATH}/tb/env_pkg.sv
${UART_IP_VERIF_PATH}/sequences/seq_pkg.sv
${UART_IP_VERIF_PATH}/testcases/test_pkg.sv
${UART_IP_VERIF_PATH}/tb/testbench.sv

