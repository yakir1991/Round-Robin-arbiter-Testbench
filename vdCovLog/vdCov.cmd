verdiWindowResize -win $_vdCoverage_1 "2750" "370" "900" "700"
gui_set_pref_value -category {coveragesetting} -key {geninfodumping} -value 1
gui_exclusion -set_force true
gui_assert_mode -mode flat
gui_class_mode -mode hier
gui_excl_mgr_flat_list -on  0
gui_covdetail_select -id  CovDetail.1   -name   Line
verdiWindowWorkMode -win $_vdCoverage_1 -coverageAnalysis
gui_open_cov  -hier coverage.vdb -testdir {} -test {coverage/design_coverage} -merge MergedTest -db_max_tests 10 -fsm transition
verdiWindowResize -win $_vdCoverage_1 "2750" "370" "1005" "711"
verdiWindowResize -win $_vdCoverage_1 "268" "291" "1005" "711"
gui_covtable_show -show  { Function Groups } -id  CoverageTable.1  -test  MergedTest
gui_list_select -id CoverageTable.1 -list covtblFGroupsList { {/$unit::arbiter_scoreboard#(4)::arbiter_cg}   }
gui_list_expand -id  CoverageTable.1   -list {covtblFGroupsList} {/$unit::arbiter_scoreboard#(4)::arbiter_cg}
gui_list_expand -id CoverageTable.1   {/$unit::arbiter_scoreboard#(4)::arbiter_cg}
gui_list_action -id  CoverageTable.1 -list {covtblFGroupsList} {/$unit::arbiter_scoreboard#(4)::arbiter_cg}  -column {Group} 
gui_list_select -id CovDetail.1 -list covergroup { {$unit::arbiter_scoreboard#(4)::arbiter_cg.ack_cp}  {/$unit::arbiter_scoreboard#(4)::arbiter_cg}   } -type { {Cover Group} {Cover Group}  }
gui_list_select -id CovDetail.1 -list covergroup { {/$unit::arbiter_scoreboard#(4)::arbiter_cg}  {$unit::arbiter_scoreboard#(4)::arbiter_cg.ack_cp}   } -type { {Cover Group} {Cover Group}  }
gui_list_action -id  CovDetail.1 -list {covergroup} {$unit::arbiter_scoreboard#(4)::arbiter_cg.ack_cp}  -type {Cover Group}
gui_list_select -id CovDetail.1 -list covergroup { {$unit::arbiter_scoreboard#(4)::arbiter_cg.ack_cp}  {$unit::arbiter_scoreboard#(4)::arbiter_cg.addr_cp}   } -type { {Cover Group} {Cover Group}  }
gui_list_select -id CovDetail.1 -list covergroup { {$unit::arbiter_scoreboard#(4)::arbiter_cg.addr_cp}  {$unit::arbiter_scoreboard#(4)::arbiter_cg.be_cp}   } -type { {Cover Group} {Cover Group}  }
gui_list_select -id CovDetail.1 -list covergroup { {$unit::arbiter_scoreboard#(4)::arbiter_cg.be_cp}  {$unit::arbiter_scoreboard#(4)::arbiter_cg.host_cp}   } -type { {Cover Group} {Cover Group}  }
gui_list_select -id CovDetail.1 -list covergroup { {$unit::arbiter_scoreboard#(4)::arbiter_cg.host_cp}  {$unit::arbiter_scoreboard#(4)::arbiter_cg.op_cp}   } -type { {Cover Group} {Cover Group}  }
gui_list_select -id CovDetail.1 -list covergroup { {$unit::arbiter_scoreboard#(4)::arbiter_cg.op_cp}  {$unit::arbiter_scoreboard#(4)::arbiter_cg.host_op_cross}   } -type { {Cover Group} {Cover Group}  }
gui_list_select -id CovDetail.1 -list covergroup { {$unit::arbiter_scoreboard#(4)::arbiter_cg.host_op_cross}  {$unit::arbiter_scoreboard#(4)::arbiter_cg.addr_be_cross}   } -type { {Cover Group} {Cover Group}  }
gui_list_select -id CovDetail.1 -list covergroup { {$unit::arbiter_scoreboard#(4)::arbiter_cg.addr_be_cross}  {$unit::arbiter_scoreboard#(4)::arbiter_cg.host_op_cross}   } -type { {Cover Group} {Cover Group}  }
gui_reload_cov 
gui_list_select -id CoverageTable.1 -list covtblFGroupsList { {/$unit::arbiter_scoreboard#(4)::arbiter_cg}   }
gui_list_select -id CoverageTable.1 -list covtblFGroupsList { {/$unit::arbiter_scoreboard#(4)::arbiter_cg}  /arbiter_tb.dut.assertions_inst::arbiter_cov   }
gui_list_expand -id  CoverageTable.1   -list {covtblFGroupsList} /arbiter_tb.dut.assertions_inst::arbiter_cov
gui_list_expand -id CoverageTable.1   /arbiter_tb.dut.assertions_inst::arbiter_cov
gui_list_action -id  CoverageTable.1 -list {covtblFGroupsList} /arbiter_tb.dut.assertions_inst::arbiter_cov  -column {Group} 
