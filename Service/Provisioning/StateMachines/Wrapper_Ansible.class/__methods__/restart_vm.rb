#
# Description: <Method description here>
#
svc=$evm.root["service"]
vms_nok=0
$evm.log(:info,"CC- checking VM ip from service #{$svc}")
svc.direct_vms.each do |vm|
  
  power_state=vm.power_state
  ip=vm.ipaddresses.first rescue nil

  $evm.log(:info,"CC- VM #{vm.name} is power #{power_state} with ip #{ip}")
  if ip.nil?
    vms_nok+=1
    if power_state=="on"
      $evm.log(:info,"  CC- stopping VM")
      $evm.root["ae_retry_interval"]="30.seconds"
      vm.stop         
    else
      $evm.log(:info,"  CC- starting VM")
      vm.start
      $evm.root["ae_retry_interval"]="90.seconds"
    end
  end


end

$evm.log(:info,"CC- #{vms_nok} VM without IP")
if vms_nok>0
    $evm.log(:info," CC- Waiting for VMs")
    $evm.root["ae_result"]="retry"
  else
    $evm.log(:info,"CC- VMs OK")
    $evm.root["ae_result"]="ok"
end
