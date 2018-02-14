#
# Description: attend la fin du playbook
#

def check_request(svc,request)
  request_state=request.request_state.downcase
  request.miq_request_tasks.each do |task|
    $evm.log(:info,"CC- checking #{task.destination}")
    unless task.destination.nil?
      if (task.destination_type.downcase rescue nil)=="service"
        $evm.log(:info,"CC- setting parent for #{task.destination.name} to #{svc.name}")
        task.destination.parent_service=svc
        task.destination.display=true
      end
    end
  end
  
  case request_state
    when "error"
      $evm.log(:info,"CC- Ressource is in ERROR state")
      $evm.root['ae_result']="error"
    when "finished"
      if request.status.downcase=="error"
        then
          $evm.log(:info,"CC- Ressource is finished with ERROR. Exiting")
          $evm.root['ae_result']="error"
        else
          $evm.log(:info,"CC- Ressource is provisionned. Exiting")
          $evm.root['ae_result']="ok"
        end
    else
      $evm.log(:info,"CC- Ressource is in #{request_state} state...retying")
      $evm.root['ae_result']="retry"
      $evm.root["ae_retry_interval"]="10.seconds"
    end
end

svc=$evm.root["service"]
requestid=$evm.get_state_var("Ansible_Request")
request=$evm.vmdb(:miq_request).find_by_id(requestid)
$evm.log(:info,"CC- request: #{request.inspect}")
if request.approval_state=="pending_approval"
  $evm.log(:info,"CC- request: #{request.inspect} is not approved => forcing")
  request.approve("admin","auto_approve")
end
check_request(svc,request)
