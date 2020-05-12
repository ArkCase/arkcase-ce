#!/bin/bash
_user_group_membership_file=./EEOC\ FOIA\ User\ Groups\ and\ Roles\ 20200424_.csv
_user_group_membership_out_file=./EEOC\ FOIA\ User\ Groups\ and\ Roles\ 20200424_2.csv
_cwd=.
_line_number_to_start_processing=3
_support_multiple_user_os_groups=0 # 1 for enable 
_common_name_first_space_last=1 # 0 for common name format to be last, first

_yaml_file_for_roles_to_groups__ldap_groups__ldap_users=${_cwd}/_yaml_file_for_roles_to_groups__ldap_groups__ldap_users.yml
> $_yaml_file_for_roles_to_groups__ldap_groups__ldap_users


cat "$_user_group_membership_file" | tr '\r\n' ' ' | tr ',' '\n'  | paste -sd',,,,,,,,,\n'  > "$_user_group_membership_out_file"

#_directory_base="DC=appdev,DC=com"
#_user_directory_base="CN=Users,DC=appdev,DC=com"
#_group_directory_base="CN=Users,DC=appdev,DC=com"

declare -A _roles_to_groups_for_arkcase_yaml
declare -a _list_of_arkcase_roles
declare -a _list_of_arkcase_groups
declare -a _list_of_user_os_group_names
declare -a _ldap_groups_for_arkcase_yaml
declare -i _ldap_groups_counter_for_arkcase_yaml
declare -a _ldap_users_for_arkcase_yaml
declare -i _ldap_users_counter_for_arkcase_yaml
declare -A _ldap_users_and_groups_for_arkcase_yaml

_ldap_groups_counter_for_arkcase_yaml=0
_ldap_users_counter_for_arkcase_yaml=0

_roles_to_groups_yaml_snippet="# used in versions 3.3.3 and up\n"
_roles_to_groups_yaml_snippet="${_roles_to_groups_yaml_snippet}roles_to_groups_yaml:\n"

_ldap_groups_yaml_snippet="ldap_groups:\n"

_ldap_users_yaml_snippet="ldap_users:\n"

_arkcase_yaml_ldap_prefix_var="ldap_prefix"
_arkcase_yaml_ldap_user_domain_var="ldap_user_domain"
_arkcase_yaml_ldap_uppercase_function_command="upper"

_roles_to_groups_for_arkcase_yaml_unsorted=${_cwd}/_roles_to_groups_for_arkcase_yaml_unsorted.txt
> $_roles_to_groups_for_arkcase_yaml_unsorted
_roles_to_groups_for_arkcase_yaml_entries=${_cwd}/_roles_to_groups_for_arkcase_yaml_entries.txt
> $_roles_to_groups_for_arkcase_yaml_entries

_ldap_groups_for_arkcase_yaml_unsorted=${_cwd}/_ldap_groups_for_arkcase_yaml_unsorted.txt
> $_ldap_groups_for_arkcase_yaml_unsorted
_ldap_groups_for_arkcase_yaml_entries=${_cwd}/_ldap_groups_for_arkcase_yaml_entries.txt
> $_ldap_groups_for_arkcase_yaml_entries

_line_counter=1
while IFS=',' read -r _user_first_name _user_last_name _user_email_address \
    _user_os_upn _user_os_id _user_arkcase_groups _user_arkcase_roles \
	_user_os_group_name _user_action_office_code _user_action_office_name
do
  #echo "$_user_first_name $_user_last_name $_user_email_address $_user_os_upn $_user_os_id $_user_arkcase_groups $_user_arkcase_roles \
	#$_user_os_group_name $_user_action_office_code $_user_action_office_name"
  if [ "$_line_counter" -ge "$_line_number_to_start_processing" ]
  then
    echo "Processing line ${_line_counter}"

# ldap_users:
  # - user_id: "{{ arkcase_admin_user }}"
    # description: ArkCase administrator
    # name: ArkCase Administrator
    # mail: "{{ server_admin }}"
    # firstName: ArkCase
    # lastName: Administrator
    # password: "{{ arkcase_admin_password }}"
    # groups:
      # - "{{ arkcase_admin_group }}"
      # - "CN={{ ldap_prefix }}ARKCASE_ENTITY_ADMINISTRATOR,{{ldap_group_base}}"
    # nonexpiring_password: yes
  # - user_id: "{{ ldap_prefix }}ann-acm"
    # description: Ann Smith
    # name: Ann Smith
    # mail: "ann-acm@armedia.com"
    # firstName: Ann
    # lastName: Smith
    # password: "{{ default_user_password }}"
    # groups:
      # - "{{ arkcase_admin_group }}"
      # - "CN={{ ldap_prefix }}ARKCASE_ENTITY_ADMINISTRATOR,{{ldap_group_base}}"
    # nonexpiring_password: yes

	  if [[ "${_user_first_name}s" != "s" && "${_user_last_name}s" != "s" ]]
	  then
		echo "  Processing user name (first last) $_user_first_name $_user_last_name" ; 
		# remove leading and trailing double quotes and spaces
        __user_first_name=$(sed -e 's/^"//' -e 's/"$//' <<<"$_user_first_name")
        ___user_first_name="$(echo "${__user_first_name}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

		# remove leading and trailing double quotes and spaces
        __user_last_name=$(sed -e 's/^"//' -e 's/"$//' <<<"$_user_last_name")
        ___user_last_name="$(echo "${__user_last_name}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
		
		# set the common name (CN) as first space last unless otherwise directed
		_user_common_name="${___user_first_name} ${___user_last_name}"
		if [ $_common_name_first_space_last -ne 1 ] ; then _user_common_name="${___user_last_name}, ${___user_first_name}" ; fi 
		
		# remove leading and trailing double quotes and spaces
        __user_email_address=$(sed -e 's/^"//' -e 's/"$//' <<<"$_user_email_address")
        ___user_email_address="$(echo "${__user_email_address}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
		
		# sAMAccountName for Everick Bowen is EBOWENS (first name initial and up to 7 characters of the last name) 
		#  and UPN is his email address EVERICK.BOWENS@EEOC.GOV.  		
		if [[ "${_user_os_id}s" == "s" ]] ; then _user_os_id_f=$(sed 's/\(.\{1\}\).*/\1/' <<< "$___user_first_name") ; _user_os_id_l=$(sed 's/\(.\{7\}\).*/\1/' <<< "$___user_last_name") ;  _user_os_id=$(echo "${_user_os_id_f^^}${_user_os_id_l^^}"); fi
		# remove leading and trailing double quotes and spaces
        __user_os_id=$(sed -e 's/^"//' -e 's/"$//' <<<"$_user_os_id")
        ___user_os_id="$(echo "${__user_os_id}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

		# remove leading and trailing double quotes and spaces
		__user_os_upn=$(sed -e 's/^"//' -e 's/"$//' <<<"$_user_os_upn")
        ___user_os_upn="$(echo "${__user_os_upn}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
				
		# since we don't have a description, we will make one from the Action Office name and Action Office code
		# remove leading and trailing double quotes and spaces
		__user_action_office_name=$(sed -e 's/^"//' -e 's/"$//' <<<"$_user_action_office_name")
        ___user_action_office_name="$(echo "${__user_action_office_name}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
		# remove leading and trailing double quotes and spaces
		__user_action_office_code=$(sed -e 's/^"//' -e 's/"$//' <<<"$_user_action_office_code")
        ___user_action_office_code="$(echo "${__user_action_office_code}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"	
		if [[ "${__user_action_office_code}s" == "s" ]] ; then _description="${__user_action_office_name}"; else _description="${__user_action_office_name} (${__user_action_office_code})" ; fi

  	    __user_os_group_name=$(sed -e 's/^"//' -e 's/"$//' <<<"$_user_os_group_name")
		___user_os_group_name="$(echo "${__user_os_group_name}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
		
		# start putting the YAML together for ldap users
		_ldap_users_yaml_snippet="${_ldap_users_yaml_snippet}  - user_id: ${___user_os_id}\n"
		_ldap_users_yaml_snippet="${_ldap_users_yaml_snippet}    description: ${_description}\n"
		_ldap_users_yaml_snippet="${_ldap_users_yaml_snippet}    name: ${_user_common_name}\n"
		_ldap_users_yaml_snippet="${_ldap_users_yaml_snippet}    mail: ${___user_email_address}\n"
		_ldap_users_yaml_snippet="${_ldap_users_yaml_snippet}    firstName: ${___user_first_name}\n"
		_ldap_users_yaml_snippet="${_ldap_users_yaml_snippet}    lastName: ${___user_last_name}\n"
		_ldap_users_yaml_snippet="${_ldap_users_yaml_snippet}    password: \"{{ default_user_password }}\"\n"	
		if [[ "${___user_os_group_name}s" != "s" ]]
		then
		  _ldap_users_yaml_snippet="${_ldap_users_yaml_snippet}    groups:\n"
			if [ $_support_multiple_user_os_groups -eq 0 ] 
			then 
			  _ldap_users_yaml_snippet="${_ldap_users_yaml_snippet}      - \"CN={{ ldap_prefix }}${___user_os_group_name},{{ldap_group_base}}\"\n"		  
			else 
			  echo "  ldap users - we don't have multiple group support yet"
			fi	
		else
 		  echo "  ldap users - not processing any groups for \"${_user_first_name}\" \"${_user_last_name}\""	
		fi
		_ldap_users_yaml_snippet="${_ldap_users_yaml_snippet}    nonexpiring_password: yes\n"
	  fi
		
# ldap_groups:
  # - description: Entity administrators
    # name: "{{ ldap_prefix }}ARKCASE_ENTITY_ADMINISTRATOR"
    # alfresco_role: SiteManager
    # alfresco_rma_role: Administrator
  # - description: Consumers
    # name: "{{ ldap_prefix }}ARKCASE_CONSUMER"
    # alfresco_role: SiteManager
    # alfresco_rma_role: Administrator
	
	  # create group list for addition to Directory through LDAP
	  #  we will want to add a length check and take action for group name when longer than 63 characters
	  #   note group description can be up to 255 characters
	  if [[ "${_user_os_group_name}s" != "s" && "${_user_os_group_name}s" != "s" ]]
	  then
  	    __user_os_group_name=$(sed -e 's/^"//' -e 's/"$//' <<<"$_user_os_group_name")
		if [ $_support_multiple_user_os_groups -eq 0 ]
		then
			# assume for now, there is one group since there are spaces in the group name and we need to figure out delimiters
			_list_of_user_os_group_names=$__user_os_group_name
			echo "  ldap groups - Processing OS group $__user_os_group_name" ; 
			_group_no_leading_or_trailing_spaces="$(echo "${__user_os_group_name}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" ; 
			echo "${_group_no_leading_or_trailing_spaces}" >> $_ldap_groups_for_arkcase_yaml_unsorted  ; 
		else
			_list_of_user_os_group_names=($__user_os_group_name)
			i=1
			for _group in ${_list_of_user_os_group_names[@]} ; 
			do 
			  echo "  ldap groups - Processing OS group $i" ; 
			  _group_no_leading_or_trailing_spaces="$(echo "${_group}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" ; 
			  # echo "$i ${_group_no_leading_or_trailing_spaces} ; 
			  echo "${_group_no_leading_or_trailing_spaces}" >> $_ldap_groups_for_arkcase_yaml_unsorted  ; 
			  i=$(( $i+1 )); 
			done
		fi
	  else
		echo "user OS group names - not adding any for \"${_user_first_name}\" \"${_user_last_name}\""
	  fi  

# roles_to_groups_yaml:
  # ROLE_ENTITY_ADMINISTRATOR:
  # - "{{ ldap_prefix }}ARKCASE_ENTITY_ADMINISTRATOR@{{ ldap_user_domain | upper }}"
  # ROLE_CONSUMER:
  # - "{{ ldap_prefix }}ARKCASE_CONSUMER@{{ ldap_user_domain | upper }}"
  
	  # add the role and group to _roles_to_groups_for_arkcase_yaml
	  if [[ "${_user_arkcase_roles}s" != "s" && "${_user_arkcase_groups}s" != "s" ]]
	  then
		__user_arkcase_roles=$(sed -e 's/^"//' -e 's/"$//' <<<"$_user_arkcase_roles")
		__user_arkcase_groups=$(sed -e 's/^"//' -e 's/"$//' <<<"$_user_arkcase_groups")
		_list_of_arkcase_roles=($__user_arkcase_roles)
		_list_of_arkcase_groups=($__user_arkcase_groups)
		i=0
		for _role in ${_list_of_arkcase_roles[@]} ; 
		do 
		  echo "  Processing role $i $_role to ${_list_of_arkcase_groups[$i]}" ; 
		  _role_no_space="$(echo "${_role}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" ; 
		  _group_no_space="$(echo "${_list_of_arkcase_groups[$i]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" ; 
		  # echo "$i $_role_no_space $_group_no_space ${_list_of_arkcase_roles[$i]} ${_list_of_arkcase_groups[$i]}" ; 
		  echo "${_role_no_space} ${_group_no_space}" >> $_roles_to_groups_for_arkcase_yaml_unsorted  ; 
		  i=$(( $i+1 )); 
		done
	  else
		echo "roles to groups - not adding any \"$_user_arkcase_roles\" and \"$_user_arkcase_groups\" for \"${_user_first_name}\" \"${_user_last_name}\""
	  fi
  else
    echo "Ignoring line ${_line_counter} since it is less than the start line - ${_line_number_to_start_processing}"
  fi
  _line_counter=$(( $_line_counter+1 ))
done < "$_user_group_membership_out_file"


# create the YAML for https://github.com/ArkCase/arkcase-ce/blob/develop/vagrant/provisioning/arkcase-dev-facts.yml
cat $_roles_to_groups_for_arkcase_yaml_unsorted | sort | uniq > $_roles_to_groups_for_arkcase_yaml_entries 
while read -r _role_and_group_line_item
do
  __role_and_group_line_item=$(sed -e 's/^"//' -e 's/"$//' <<<"$_role_and_group_line_item")
  __role_and_group_line_items=($_role_and_group_line_item)
  i=0; 
  for _entry in ${__role_and_group_line_items[@]} ; do
    _entry_no_space="$(echo "${_entry}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
	if [ $i -eq 0 ] ; 
	then
	  _roles_to_groups_yaml_snippet="${_roles_to_groups_yaml_snippet}  ${_entry}:\n"
    else
	  _group_entry=$(echo $_entry | sed 's/@.*$//')
	  _roles_to_groups_yaml_snippet="${_roles_to_groups_yaml_snippet}  - \"{{ ${_arkcase_yaml_ldap_prefix_var} }}${_group_entry}@{{ ${_arkcase_yaml_ldap_user_domain_var} | ${_arkcase_yaml_ldap_uppercase_function_command} }}\"\n"  
    fi
	i=$(( $i+1 ));
  done

done < "$_roles_to_groups_for_arkcase_yaml_entries"
echo -e "$_roles_to_groups_yaml_snippet"

# create the YAML for https://github.com/ArkCase/arkcase-ce/blob/develop/vagrant/provisioning/arkcase-dev-facts.yml
cat $_ldap_groups_for_arkcase_yaml_unsorted | sort | uniq > $_ldap_groups_for_arkcase_yaml_entries 
while read -r _group_line_item
do
  __group_line_item=$(sed -e 's/^"//' -e 's/"$//' <<<"$_group_line_item")
  # assume for now, there is one group since there are spaces in the group name and we need to figure out delimiters

  if [ $_support_multiple_user_os_groups -eq 0 ]
  then
	# assume for now, there is one group since there are spaces in the group name and we need to figure out delimiters
	_entry_no_space="$(echo "${__group_line_item}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
	_ldap_groups_yaml_snippet="${_ldap_groups_yaml_snippet} - description: ${_entry_no_space}\n"
	_ldap_groups_yaml_snippet="${_ldap_groups_yaml_snippet}   name: {{ ${_arkcase_yaml_ldap_prefix_var} }}${_entry_no_space}\n"
	_ldap_groups_yaml_snippet="${_ldap_groups_yaml_snippet}   alfresco_role: SiteManager\n"
	_ldap_groups_yaml_snippet="${_ldap_groups_yaml_snippet}   alfresco_rma_role: Administrator\n"
  else
	  __group_line_items=($__group_line_item)
	  i=0; 
	  for _entry in ${__group_line_items[@]} ; do
		_entry_no_space="$(echo "${_entry}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
		_ldap_groups_yaml_snippet="${_ldap_groups_yaml_snippet} - description: ${_entry_no_space}\n"
		_ldap_groups_yaml_snippet="${_ldap_groups_yaml_snippet}   name: {{ ${_arkcase_yaml_ldap_prefix_var} }}${_entry_no_space}\n"
		_ldap_groups_yaml_snippet="${_ldap_groups_yaml_snippet}   alfresco_role: SiteManager\n"
		_ldap_groups_yaml_snippet="${_ldap_groups_yaml_snippet}   alfresco_rma_role: Administrator\n"
		i=$(( $i+1 ));
	  done
  fi
done < "$_ldap_groups_for_arkcase_yaml_entries"

echo -e "$_ldap_groups_yaml_snippet"
echo -e "$_ldap_users_yaml_snippet"

echo "put all YAML into a file for execution"
echo -e "$_roles_to_groups_yaml_snippet" >> $_yaml_file_for_roles_to_groups__ldap_groups__ldap_users
echo -e "$_ldap_groups_yaml_snippet" >> $_yaml_file_for_roles_to_groups__ldap_groups__ldap_users
echo -e "$_ldap_users_yaml_snippet" >> $_yaml_file_for_roles_to_groups__ldap_groups__ldap_users

