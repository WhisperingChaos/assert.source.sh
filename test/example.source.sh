hostNameVerify(){
	local -r hostName="$1"
	
	local -ri hostLen="${#hostName}"
	local -ri hostMin=4

	if [ $hostLen -lt $hostMin ]; then
	   msg_err "Error: hostName='$hostName' length=$hostLen less than minAllowed=$hostMin"
		return
	fi
	local -ri hostMax=$(getconf HOST_NAME_MAX)
	if [ $hostLen -gt $hostMax ]; then
	   msg_err "Error: hostName='$hostName' length=$hostLen greater than maxAllowed=$hostMin"
		return
	fi
	local -r hostRegexp='^hNm[[:alnum:]]+$'
	if ! [[ $hostName =~ $hostRegexp ]]; then
	   msg_err "Error: hostName='$hostName' fails to conform to hostRegexp='$hostRegexp'"
		return
	fi
}

msg_err(){
   echo "$1" >&2
   return 1
}
