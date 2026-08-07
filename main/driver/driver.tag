<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>
<tagfile doxygen_version="1.13.2" doxygen_gitid="26342b775ea25e6fefb53220926b20702c56fcb3">
  <compound kind="struct">
    <name>ethosu_config</name>
    <filename>group__ethosu__driver__structs.html</filename>
    <anchor>structethosu__config</anchor>
  </compound>
  <compound kind="struct">
    <name>ethosu_driver</name>
    <filename>group__ethosu__driver__structs.html</filename>
    <anchor>structethosu__driver</anchor>
  </compound>
  <compound kind="struct">
    <name>ethosu_driver_version</name>
    <filename>group__ethosu__driver__structs.html</filename>
    <anchor>structethosu__driver__version</anchor>
  </compound>
  <compound kind="struct">
    <name>ethosu_hw_info</name>
    <filename>group__ethosu__driver__structs.html</filename>
    <anchor>structethosu__hw__info</anchor>
  </compound>
  <compound kind="struct">
    <name>ethosu_id</name>
    <filename>group__ethosu__driver__structs.html</filename>
    <anchor>structethosu__id</anchor>
  </compound>
  <compound kind="struct">
    <name>ethosu_job</name>
    <filename>group__ethosu__driver__structs.html</filename>
    <anchor>structethosu__job</anchor>
  </compound>
  <compound kind="group">
    <name>ethosu_driver_structs</name>
    <title>Structures</title>
    <filename>group__ethosu__driver__structs.html</filename>
    <class kind="struct">ethosu_driver</class>
    <class kind="struct">ethosu_driver_version</class>
    <class kind="struct">ethosu_job</class>
    <class kind="struct">ethosu_id</class>
    <class kind="struct">ethosu_config</class>
    <class kind="struct">ethosu_hw_info</class>
  </compound>
  <compound kind="group">
    <name>ethosu_public_api</name>
    <title>Functions</title>
    <filename>group__ethosu__public__api.html</filename>
    <member kind="function">
      <type>int</type>
      <name>ethosu_init</name>
      <anchorfile>group__ethosu__public__api.html</anchorfile>
      <anchor>gae021e7e1e40a33303dcc17041a1f2911</anchor>
      <arglist>(struct ethosu_driver *drv, void *const base_address, const void *fast_memory, const size_t fast_memory_size, uint32_t secure_enable, uint32_t privilege_enable)</arglist>
    </member>
    <member kind="function">
      <type>void</type>
      <name>ethosu_deinit</name>
      <anchorfile>group__ethosu__public__api.html</anchorfile>
      <anchor>ga7d07a2c3e7c66236d31986c191c7c6e1</anchor>
      <arglist>(struct ethosu_driver *drv)</arglist>
    </member>
    <member kind="function">
      <type>int</type>
      <name>ethosu_soft_reset</name>
      <anchorfile>group__ethosu__public__api.html</anchorfile>
      <anchor>ga480a7f7b324b3be61c1a9ffc92be9f3a</anchor>
      <arglist>(struct ethosu_driver *drv)</arglist>
    </member>
    <member kind="function">
      <type>int</type>
      <name>ethosu_request_power</name>
      <anchorfile>group__ethosu__public__api.html</anchorfile>
      <anchor>ga296ee3333eec28a0aa57940af26664c9</anchor>
      <arglist>(struct ethosu_driver *drv)</arglist>
    </member>
    <member kind="function">
      <type>void</type>
      <name>ethosu_release_power</name>
      <anchorfile>group__ethosu__public__api.html</anchorfile>
      <anchor>gaa7aa51e0c8d7757f3ca28b0ad4303558</anchor>
      <arglist>(struct ethosu_driver *drv)</arglist>
    </member>
    <member kind="function">
      <type>void</type>
      <name>ethosu_get_driver_version</name>
      <anchorfile>group__ethosu__public__api.html</anchorfile>
      <anchor>ga061d3040dbd395073b51968bc2e91d55</anchor>
      <arglist>(struct ethosu_driver_version *ver)</arglist>
    </member>
    <member kind="function">
      <type>void</type>
      <name>ethosu_get_hw_info</name>
      <anchorfile>group__ethosu__public__api.html</anchorfile>
      <anchor>ga583bd9f7a0ae2cabfecf6b2843adcc56</anchor>
      <arglist>(struct ethosu_driver *drv, struct ethosu_hw_info *hw)</arglist>
    </member>
    <member kind="function">
      <type>int</type>
      <name>ethosu_invoke_v3</name>
      <anchorfile>group__ethosu__public__api.html</anchorfile>
      <anchor>ga6965f708d5951842cd6f8cfe26a35868</anchor>
      <arglist>(struct ethosu_driver *drv, const void *custom_data_ptr, const int custom_data_size, uint64_t *const base_addr, const size_t *base_addr_size, const int num_base_addr, void *user_arg)</arglist>
    </member>
    <member kind="function">
      <type>int</type>
      <name>ethosu_invoke_async</name>
      <anchorfile>group__ethosu__public__api.html</anchorfile>
      <anchor>ga7a052a3c7ea0c14992b3dc2cd6e20d0b</anchor>
      <arglist>(struct ethosu_driver *drv, const void *custom_data_ptr, const int custom_data_size, uint64_t *const base_addr, const size_t *base_addr_size, const int num_base_addr, void *user_arg)</arglist>
    </member>
    <member kind="function">
      <type>int</type>
      <name>ethosu_wait</name>
      <anchorfile>group__ethosu__public__api.html</anchorfile>
      <anchor>ga33e63dcf2625e5b10d07193490b6323b</anchor>
      <arglist>(struct ethosu_driver *drv, bool block)</arglist>
    </member>
    <member kind="function">
      <type>struct ethosu_driver *</type>
      <name>ethosu_reserve_driver</name>
      <anchorfile>group__ethosu__public__api.html</anchorfile>
      <anchor>ga92c30eeceb5152d6f06ff9c5859a1381</anchor>
      <arglist>(void)</arglist>
    </member>
    <member kind="function">
      <type>void</type>
      <name>ethosu_release_driver</name>
      <anchorfile>group__ethosu__public__api.html</anchorfile>
      <anchor>ga6e97d1e64ca7d2cbaa89230bce0a2dde</anchor>
      <arglist>(struct ethosu_driver *drv)</arglist>
    </member>
    <member kind="function">
      <type>void</type>
      <name>ethosu_irq_handler</name>
      <anchorfile>group__ethosu__public__api.html</anchorfile>
      <anchor>ga55fec2a7ca5b5b51dc7c3d18914a3f03</anchor>
      <arglist>(struct ethosu_driver *drv)</arglist>
    </member>
  </compound>
  <compound kind="group">
    <name>ethosu_callback_api</name>
    <title>Platform hooks</title>
    <filename>group__ethosu__callback__api.html</filename>
    <member kind="function">
      <type>void</type>
      <name>ethosu_flush_dcache</name>
      <anchorfile>group__ethosu__callback__api.html</anchorfile>
      <anchor>gae23e3120197768bbd1b21fd03823183a</anchor>
      <arglist>(const uint64_t *base_addr, const size_t *base_addr_size, int num_base_addr)</arglist>
    </member>
    <member kind="function">
      <type>void</type>
      <name>ethosu_invalidate_dcache</name>
      <anchorfile>group__ethosu__callback__api.html</anchorfile>
      <anchor>ga608e58ae2673e286df81660936889f66</anchor>
      <arglist>(const uint64_t *base_addr, const size_t *base_addr_size, int num_base_addr)</arglist>
    </member>
    <member kind="function">
      <type>void *</type>
      <name>ethosu_mutex_create</name>
      <anchorfile>group__ethosu__callback__api.html</anchorfile>
      <anchor>ga263037460610168af74801efae3385a2</anchor>
      <arglist>(void)</arglist>
    </member>
    <member kind="function">
      <type>void</type>
      <name>ethosu_mutex_destroy</name>
      <anchorfile>group__ethosu__callback__api.html</anchorfile>
      <anchor>ga9b812e75be8b38f21234da2c855b1ff1</anchor>
      <arglist>(void *mutex)</arglist>
    </member>
    <member kind="function">
      <type>void *</type>
      <name>ethosu_semaphore_create</name>
      <anchorfile>group__ethosu__callback__api.html</anchorfile>
      <anchor>ga4bb4d49e7ba5ec009af2796fe77e349a</anchor>
      <arglist>(void)</arglist>
    </member>
    <member kind="function">
      <type>void</type>
      <name>ethosu_semaphore_destroy</name>
      <anchorfile>group__ethosu__callback__api.html</anchorfile>
      <anchor>ga501658b237bf401cda781eccfd1f358a</anchor>
      <arglist>(void *sem)</arglist>
    </member>
    <member kind="function">
      <type>int</type>
      <name>ethosu_mutex_lock</name>
      <anchorfile>group__ethosu__callback__api.html</anchorfile>
      <anchor>ga17827ea06a500bad6bda5aa9e751f4f1</anchor>
      <arglist>(void *mutex)</arglist>
    </member>
    <member kind="function">
      <type>int</type>
      <name>ethosu_mutex_unlock</name>
      <anchorfile>group__ethosu__callback__api.html</anchorfile>
      <anchor>gaa0075944c4284c6ced884698e560eea4</anchor>
      <arglist>(void *mutex)</arglist>
    </member>
    <member kind="function">
      <type>int</type>
      <name>ethosu_semaphore_take</name>
      <anchorfile>group__ethosu__callback__api.html</anchorfile>
      <anchor>ga9792e5bb9f00971f20037db9a9982725</anchor>
      <arglist>(void *sem, uint64_t timeout)</arglist>
    </member>
    <member kind="function">
      <type>int</type>
      <name>ethosu_semaphore_give</name>
      <anchorfile>group__ethosu__callback__api.html</anchorfile>
      <anchor>ga71614f92cb653bed7b7632b0362939b4</anchor>
      <arglist>(void *sem)</arglist>
    </member>
    <member kind="function">
      <type>void</type>
      <name>ethosu_inference_begin</name>
      <anchorfile>group__ethosu__callback__api.html</anchorfile>
      <anchor>ga04b34ee5d2328ecdfc7d464761f6cb7f</anchor>
      <arglist>(struct ethosu_driver *drv, void *user_arg)</arglist>
    </member>
    <member kind="function">
      <type>void</type>
      <name>ethosu_inference_end</name>
      <anchorfile>group__ethosu__callback__api.html</anchorfile>
      <anchor>gabe0e7014df596c89393c3bce70c4ee0c</anchor>
      <arglist>(struct ethosu_driver *drv, void *user_arg)</arglist>
    </member>
    <member kind="function">
      <type>uint64_t</type>
      <name>ethosu_address_remap</name>
      <anchorfile>group__ethosu__callback__api.html</anchorfile>
      <anchor>gaada1c421a052cbdcfd5f1c8c31cd8c4a</anchor>
      <arglist>(uint64_t address, int index)</arglist>
    </member>
    <member kind="function">
      <type>unsigned int</type>
      <name>ethosu_config_select</name>
      <anchorfile>group__ethosu__callback__api.html</anchorfile>
      <anchor>ga872178ba3393d3f21c57c950ed82fb1a</anchor>
      <arglist>(uint64_t address, int index)</arglist>
    </member>
  </compound>
  <compound kind="group">
    <name>ethosu_pmu_api</name>
    <title>Performance Monitoring Unit API</title>
    <filename>group__ethosu__pmu__api.html</filename>
    <member kind="function">
      <type>void</type>
      <name>ETHOSU_PMU_Enable</name>
      <anchorfile>group__ethosu__pmu__api.html</anchorfile>
      <anchor>gac4ed0239a963456a74e18ec7a06fd086</anchor>
      <arglist>(struct ethosu_driver *drv)</arglist>
    </member>
    <member kind="function">
      <type>void</type>
      <name>ETHOSU_PMU_Disable</name>
      <anchorfile>group__ethosu__pmu__api.html</anchorfile>
      <anchor>gaf976f4e4d18229593591bdf984645018</anchor>
      <arglist>(struct ethosu_driver *drv)</arglist>
    </member>
    <member kind="function">
      <type>void</type>
      <name>ETHOSU_PMU_Set_EVTYPER</name>
      <anchorfile>group__ethosu__pmu__api.html</anchorfile>
      <anchor>ga73f8bf9079d47e1d6afe9bf7a49f6999</anchor>
      <arglist>(struct ethosu_driver *drv, uint32_t num, enum ethosu_pmu_event_type type)</arglist>
    </member>
    <member kind="function">
      <type>uint32_t</type>
      <name>ETHOSU_PMU_Get_NumEventCounters</name>
      <anchorfile>group__ethosu__pmu__api.html</anchorfile>
      <anchor>ga6e52be0fc9b15f9351e83698bd9b5888</anchor>
      <arglist>(void)</arglist>
    </member>
    <member kind="function">
      <type>enum ethosu_pmu_event_type</type>
      <name>ETHOSU_PMU_Get_EVTYPER</name>
      <anchorfile>group__ethosu__pmu__api.html</anchorfile>
      <anchor>ga2450c677d035e1e2dc51c31b1feb2df8</anchor>
      <arglist>(struct ethosu_driver *drv, uint32_t num)</arglist>
    </member>
    <member kind="function">
      <type>void</type>
      <name>ETHOSU_PMU_CYCCNT_Reset</name>
      <anchorfile>group__ethosu__pmu__api.html</anchorfile>
      <anchor>gabe2a2b4b99bf753d02b5683fab77988c</anchor>
      <arglist>(struct ethosu_driver *drv)</arglist>
    </member>
    <member kind="function">
      <type>void</type>
      <name>ETHOSU_PMU_EVCNTR_ALL_Reset</name>
      <anchorfile>group__ethosu__pmu__api.html</anchorfile>
      <anchor>ga6bfb8e6dbb653f003fd4a196b895a79d</anchor>
      <arglist>(struct ethosu_driver *drv)</arglist>
    </member>
    <member kind="function">
      <type>void</type>
      <name>ETHOSU_PMU_CNTR_Enable</name>
      <anchorfile>group__ethosu__pmu__api.html</anchorfile>
      <anchor>ga100f5c40ed0cfda7fd0f6dae35c51da2</anchor>
      <arglist>(struct ethosu_driver *drv, uint32_t mask)</arglist>
    </member>
    <member kind="function">
      <type>void</type>
      <name>ETHOSU_PMU_CNTR_Disable</name>
      <anchorfile>group__ethosu__pmu__api.html</anchorfile>
      <anchor>gae13ce2d6a114658e6bf2d9d70135eeb8</anchor>
      <arglist>(struct ethosu_driver *drv, uint32_t mask)</arglist>
    </member>
    <member kind="function">
      <type>uint32_t</type>
      <name>ETHOSU_PMU_CNTR_Status</name>
      <anchorfile>group__ethosu__pmu__api.html</anchorfile>
      <anchor>ga285ba30593341536860b81151ec202f7</anchor>
      <arglist>(struct ethosu_driver *drv)</arglist>
    </member>
    <member kind="function">
      <type>uint64_t</type>
      <name>ETHOSU_PMU_Get_CCNTR</name>
      <anchorfile>group__ethosu__pmu__api.html</anchorfile>
      <anchor>ga99ab8589f4909184d0a1038887f1228d</anchor>
      <arglist>(struct ethosu_driver *drv)</arglist>
    </member>
    <member kind="function">
      <type>void</type>
      <name>ETHOSU_PMU_Set_CCNTR</name>
      <anchorfile>group__ethosu__pmu__api.html</anchorfile>
      <anchor>ga598367d9920c99b08d062b0684593e9a</anchor>
      <arglist>(struct ethosu_driver *drv, uint64_t val)</arglist>
    </member>
    <member kind="function">
      <type>uint32_t</type>
      <name>ETHOSU_PMU_Get_EVCNTR</name>
      <anchorfile>group__ethosu__pmu__api.html</anchorfile>
      <anchor>ga61c678210a7d508e9436c144964246ff</anchor>
      <arglist>(struct ethosu_driver *drv, uint32_t num)</arglist>
    </member>
    <member kind="function">
      <type>void</type>
      <name>ETHOSU_PMU_Set_EVCNTR</name>
      <anchorfile>group__ethosu__pmu__api.html</anchorfile>
      <anchor>ga9e64f737eaffba38af803a91696f1f19</anchor>
      <arglist>(struct ethosu_driver *drv, uint32_t num, uint32_t val)</arglist>
    </member>
    <member kind="function">
      <type>uint32_t</type>
      <name>ETHOSU_PMU_Get_CNTR_OVS</name>
      <anchorfile>group__ethosu__pmu__api.html</anchorfile>
      <anchor>ga8bd68f0c49c74fe81bf91867fff71c43</anchor>
      <arglist>(struct ethosu_driver *drv)</arglist>
    </member>
    <member kind="function">
      <type>void</type>
      <name>ETHOSU_PMU_Set_CNTR_OVS</name>
      <anchorfile>group__ethosu__pmu__api.html</anchorfile>
      <anchor>gab6656b95629a2b087f7e47dc5d0cc897</anchor>
      <arglist>(struct ethosu_driver *drv, uint32_t mask)</arglist>
    </member>
    <member kind="function">
      <type>void</type>
      <name>ETHOSU_PMU_Set_CNTR_IRQ_Enable</name>
      <anchorfile>group__ethosu__pmu__api.html</anchorfile>
      <anchor>ga25620215f065e2e192299d7cca9c3c39</anchor>
      <arglist>(struct ethosu_driver *drv, uint32_t mask)</arglist>
    </member>
    <member kind="function">
      <type>void</type>
      <name>ETHOSU_PMU_Set_CNTR_IRQ_Disable</name>
      <anchorfile>group__ethosu__pmu__api.html</anchorfile>
      <anchor>ga55731dad7fd178f52f3f17bf9e696187</anchor>
      <arglist>(struct ethosu_driver *drv, uint32_t mask)</arglist>
    </member>
    <member kind="function">
      <type>uint32_t</type>
      <name>ETHOSU_PMU_Get_IRQ_Enable</name>
      <anchorfile>group__ethosu__pmu__api.html</anchorfile>
      <anchor>gabcfa90c7c1a1078a13c608986f65a893</anchor>
      <arglist>(struct ethosu_driver *drv)</arglist>
    </member>
    <member kind="function">
      <type>void</type>
      <name>ETHOSU_PMU_CNTR_Increment</name>
      <anchorfile>group__ethosu__pmu__api.html</anchorfile>
      <anchor>gaab2e8591bd63f87dffb38e1cfa6df5e9</anchor>
      <arglist>(struct ethosu_driver *drv, uint32_t mask)</arglist>
    </member>
    <member kind="function">
      <type>void</type>
      <name>ETHOSU_PMU_PMCCNTR_CFG_Set_Start_Event</name>
      <anchorfile>group__ethosu__pmu__api.html</anchorfile>
      <anchor>gaebaab4ed38f8dee05ad50b1eac8a73b3</anchor>
      <arglist>(struct ethosu_driver *drv, enum ethosu_pmu_event_type start_event)</arglist>
    </member>
    <member kind="function">
      <type>void</type>
      <name>ETHOSU_PMU_PMCCNTR_CFG_Set_Stop_Event</name>
      <anchorfile>group__ethosu__pmu__api.html</anchorfile>
      <anchor>ga8cd24678c33e3d238ec0866e61150bb4</anchor>
      <arglist>(struct ethosu_driver *drv, enum ethosu_pmu_event_type stop_event)</arglist>
    </member>
    <member kind="function">
      <type>uint32_t</type>
      <name>ETHOSU_PMU_Get_QREAD</name>
      <anchorfile>group__ethosu__pmu__api.html</anchorfile>
      <anchor>ga2530cb39de40e314b7a19e42f220ab2f</anchor>
      <arglist>(struct ethosu_driver *drv)</arglist>
    </member>
    <member kind="function">
      <type>uint32_t</type>
      <name>ETHOSU_PMU_Get_STATUS</name>
      <anchorfile>group__ethosu__pmu__api.html</anchorfile>
      <anchor>ga511b1edd27d2afb94205976f5da84281</anchor>
      <arglist>(struct ethosu_driver *drv)</arglist>
    </member>
  </compound>
  <compound kind="page">
    <name>index</name>
    <title>Driver</title>
    <filename>index.html</filename>
    <docanchor file="index.html" title="Driver">mainpage</docanchor>
    <docanchor file="index.html" title="Data caching">data-caching</docanchor>
    <docanchor file="index.html" title="Mutex and semaphores">mutex-and-semaphores</docanchor>
    <docanchor file="index.html" title="Begin/End inference callbacks">beginend-inference-callbacks</docanchor>
    <docanchor file="index.html" title="Driver Configuration">driver_configuration</docanchor>
    <docanchor file="index.html" title="PMU example">pmu_example</docanchor>
  </compound>
</tagfile>
