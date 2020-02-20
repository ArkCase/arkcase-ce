# See: https://www.petri.com/using-nat-virtual-switch-hyper-v


If ("ExternalSwitch" -in (Get-VMSwitch | Select-Object -ExpandProperty Name) -eq $FALSE) {
    'Creating external switch named "ExternalSwitch" on Windows Hyper-V host...'
    
	$InterfaceName = (Get-NetRoute | ? DestinationPrefix -eq '0.0.0.0/0' | Get-NetIPInterface | Where ConnectionState -eq 'Connected').InterfaceAlias
	
	New-VMSwitch -name ExternalSwitch -NetAdapterName $InterfaceName -AllowManagementOs $true
}
else {
    '"ExternalSwitch" for dynamic IP configuration already exists; skipping'
}

Set-NetFirewallProfile -Name domain -DisabledInterfaceAliases "vEthernet (ExternalSwitch)"
Set-NetFirewallProfile -Name private -DisabledInterfaceAliases "vEthernet (ExternalSwitch)"
Set-NetFirewallProfile -Name public -DisabledInterfaceAliases "vEthernet (ExternalSwitch)"


vagrant plugin install vagrant-reload

packer build centos7-hyper-v.json
