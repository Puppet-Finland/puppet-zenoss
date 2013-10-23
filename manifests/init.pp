class zenoss {
    class client {
        $zenoss_interface = hiera('zenoss::interface', undef)
        
        $ip_fact_for_zenoss = $zenoss_interface ? {
            undef   => 'ipaddress',
            default => "ipaddress_${zenoss_interface}",
        }

        @@zenoss_host { "$fqdn":
            #ensure => present,
            alias => "$hostname",
            ip => inline_template("<%= scope.lookupvar('$ip_fact_for_zenoss') %>"),
            zenosstype => "$kernel",
            zenosscollector => "$zenosscollector",
            serialnumber => "$serialnumber",
            grouppath => hiera('zenoss::group_path',['/Unknown']),
            systempath => hiera('zenoss::system_path',['/Unknown']),
       }
}
    
    class server {
        $zenoss_api_user = hiera('zenoss::zenoss_api_user')
        $zenoss_api_password = hiera('zenoss:zenoss_api_password')
        $zenoss_host_server = hiera('zenoss::zenoss_host_server',"zenoss.${domain}")
        Zenoss_host <<| |>> {
            zenossuri => "http://${zenoss_api_user}:${zenoss_api_password}@${zenoss_host_server}:8080/zport/dmd"
        }
    }

}

