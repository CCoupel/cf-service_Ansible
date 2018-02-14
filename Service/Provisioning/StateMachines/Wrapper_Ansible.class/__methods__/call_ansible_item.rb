#
# Description: appel le catalogItem de postprovisionning en récupérant les VMs a partir du service en cours
#

def setup_catalog_item_options(dialog_options,template,svc,vms)
  dialog_options={} if dialog_options.nil?
  vm=vms.first rescue vms
  $evm.object.attributes.each { |k,v| $evm.log(:info,"  CC- object[#{k}]=#{v.inspect}") }
  $evm.root.attributes.each { |k,v| $evm.log(:info,"  CC- root[#{k}]=#{v.inspect}") }
  #we look for all extravar declared in the catalogitem and evaluate the value from the instance
  extra_vars=template[:options][:config_info][:provision][:extra_vars]
  extra_vars.each { |var,param|
    $evm.log(:info,"CC- evaluating '#{var}' object=>'#{$evm.object[param.to_s].inspect}' root=>'#{$evm.root[param.to_s].inspect}' from param='#{param[:default]}'")
    obj_var=$evm.object[param[:default].to_s]||$evm.root[param[:default].to_s] rescue nil 
    unless obj_var.nil?
      dialog_var=eval(obj_var) rescue nil 
      $evm.log(:info,"\tCC- evaluating '#{obj_var}'='#{dialog_var}'")
      dialog_options["param_#{var}"]=dialog_var unless dialog_var.nil?
      dialog_options[var]=dialog_var unless dialog_var.nil?
    end
    $evm.log(:info,"  CC- evaluated #{obj_var} to #{dialog_var}")
  }
#  dialog_options["hosts"]=svc.options[:dialog]["hosts"]
#  dialog_options["ansible_groups"]=svc.options[:dialog]["ansible_groups"]
  
  return dialog_options
end

def mk_request(svc,vms,catalogItem)
  dialog_options=svc.options[:dialog]
  dialog_options=setup_catalog_item_options(dialog_options,catalogItem,svc,vms) 
  $evm.log(:info, "CC- running template #{catalogItem} with: #{dialog_options}")
  req=$evm.execute('create_service_provision_request', catalogItem, dialog_options)
  return req
end

# récuperation du catalog item à partir de l'intance
svc=$evm.root["service"]
until svc.parent_service.nil? do svc=svc.parent_service end
catalogItem=$evm.object["catalogItem"]
$evm.log(:info,"CC- starting Ansible #{catalogItem} for service #{svc.name rescue nil}") 
catalogItem=$evm.vmdb(:service_template).find_by_name(catalogItem) rescue nil
if catalogItem.nil?
  $evm.log(:info, "CC- catalog template '#{$evm.object["Playbook_service"]}' not found.")
  $evm.root['ae_result'] = 'error'
  exit MIQ_ERROR
end


request=mk_request(svc, svc.vms, catalogItem)
$evm.log(:info,"CC- Ansible Request ID=#{request.id}")
$evm.set_state_var("Ansible_Request", request.id)
