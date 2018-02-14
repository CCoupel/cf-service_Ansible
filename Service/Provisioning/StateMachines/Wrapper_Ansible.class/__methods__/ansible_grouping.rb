#
# Description: <Method description here>
#
# inclure en entete de playbook:
#- name: bootstrap
#  hosts: localhost
#  connection: local
#  gather_facts: false
#  tasks:
#  - name: greate groups
#    add_host:
#      name: "{{ item.0 }}"
#      group: "{{ item.1 }}"
#    with_items:
#    - "{{ ansible_groups }}"

prov=$evm.root["miq_provision"]
svc=$evm.root["service"]
until svc.parent_service.nil? do svc=svc.parent_service end
ansible_groups={}

$evm.log(:info,"CC- prov=#{prov.inspect}")
$evm.log(:info,"CC- svc=#{svc.inspect}")
#$evm.log(:info,"CC- root=#{$evm.root.attributes}")

svc.get_dialog_option("Array::dialog_option_0_Ansible_Groups").split(",").each do|grp| 
  $evm.log(:info,"CC- managing group #{grp}")
  ansible_groups[grp]=nil
  end rescue nil
exit MIQ_OK if ansible_groups.nil?

children=svc.direct_service_children
#on recupere les sous services existant
$evm.log(:info,"CC- on recupere les sous services existant")
children.each do |child_svc|
#  $evm.log(:info,"CC- check if #{child_svc.name} is in ansible_groups")
#  if ansible_groups.key?(child_svc.name)
     $evm.log(:info,"  CC- adding to ansible_groups")
    ansible_groups[child_svc.name]=child_svc
#  end
end

#on créé les sous services manquants
$evm.log(:info,"CC- on créé les sous services manquants")
ansible_groups.each do |group,child_svc|
  $evm.log(:info,"CC- checking if #{group} service exists")
  if child_svc.nil?
     $evm.log(:info,"  CC- creating service")
    child_svc=$evm.vmdb(:service).create(:name=>group)
    child_svc.parent_service=svc
    child_svc.display=true
    svc.options.each {|k,v| child_svc.set_dialog_option(k,v)}
    child_svc.set_dialog_option("Array::dialog_option_0_Ansible_Groups",group)
  end
  ansible_groups[group]=child_svc
end

#on affecte les VMs non affectées
#while svc.direct_vms.count>0 do
#  ansible_groups.each do |group,child_svc|
#    $evm.log(:info,"CC- attaching VM=#{svc.direct_vms.first} to service=#{child_svc.name rescue nil}")
#    vm=svc.direct_vms.first
#    vm.remove_from_service
#    vm.add_to_service(child_svc)
#  end
#end

# on recréé le JSON de groupes
$evm.log(:info,"CC- on recréé le JSON des groupes")
inventaire=nil
svc.direct_service_children.each do |child_svc|
  $evm.log(:info,"CC- on recréé le JSON des groupes #{child_svc.name}")
  inventaire+="," unless inventaire.nil?
  inventaire="" if inventaire.nil?
  inventaire+='{"ip":"'+child_svc.name+'",'
      #inventaire+='"groups":["",'
  inventaire+='"groups":'
  groups=[]
      child_svc.tags.each {|tag|
        #inventaire+=',"'+tag+'"'
        groups << tag
      }
  inventaire+=groups.to_s+'}'
      #inventaire+=']}'
  $evm.log(:info,"CC- on recréé le JSON des vms ")
  if ansible_groups.key?child_svc.name
    child_svc.direct_vms.each do |vm|
        $evm.log(:info,"CC- on recréé le JSON #{vm.ipaddresses rescue nil }")
      #json[vm.miq_provision.get_option(:ip_addr)]=child_svc.name
      #groups+='["'+vm.miq_provision.get_option(:ip_addr)+'",'
      # groups+='"'+child_svc.name+'"],'
      unless vm.ipaddresses.first.nil?
        
        inventaire+=',{"ip":"'+vm.ipaddresses.first+'",'
        #inventaire+='"groups":["'+child_svc.name+'"'
        inventaire+='"groups":'
        groups=[child_svc.name]
        vm.tags.each {|tag|
          #inventaire+=',"'+tag+'"'
          groups << tag
        }
        #inventaire+=']}'
        inventaire+=groups.to_s+'}'
      end
    end
  end
end

#on créé l'inventaire
  hosts=""
  svc.vms.each { |vm| 
    ip=vm.ipaddresses.first rescue nil
    hosts.concat("#{ip}, ")
    $evm.log(:info, "CC- adding host #{vm.name} (#{ip}) to inventory")
  }

$evm.log(:info,"CC- groups=[#{inventaire}]")
$evm.log(:info,"CC- hosts=#{hosts}")
svc.set_dialog_option("dialog_param_ansible_groups","[#{inventaire}]")
svc.set_dialog_option("ansible_groups","[#{inventaire}]")
svc.options[:dialog]["hosts"]=hosts
svc.set_dialog_option("hosts",hosts)
$evm.root["ansible_groups"]=inventaire
