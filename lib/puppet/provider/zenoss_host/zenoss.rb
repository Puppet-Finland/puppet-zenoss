
# Puppet Provider Zenoss
Puppet::Type.type(:zenoss_host).provide(:zenoss) do 
    desc 'Provider for a ZenOSS monitored host'

    require 'xmlrpc/client'

    def initialize(resources = nil)
        super
        printmsg 'Called initialize.'
    end
    
    def printmsg(msg)
        debug("==> #{msg}")
    end

    def printmsgout(msg)
        debug("<== #{msg}")
    end

    
    # This method checks if a given device exists in the given device path
    # it is called with, to check if a device was already added
    def existsDevice(_devName, _devPath)
        begin
            printmsg('calling existsDevice...')
            uribase = resource[:zenossuri]
            uriext = "/Devices#{_devPath}/devices/#{_devName}"
            uri = "#{uribase}#{uriext}"
            debug("The URI: #{uri}")
            s = XMLRPC::Client.new2(uri)
            begin
                debug("get Id: #{s.call('getId')}")
                result = true                           # device exists
                return result
            rescue XMLRPC::FaultException => fe         # device does not exist
                result = false
                return result
            ensure
                printmsgout "result: #{result}"
            end
        rescue XMLRPC::FaultException => e
            err(e.faultCode)
            err(e.faultString)
        end
    end


    # This method loads a device into zenoss
    # The device is added with its IP adress as name, which is necessary to 
    # cope with environments where no DNS server is available.
    # After the device was successfully added, we rename it
    def loadDevice(_devName, _devPath)
        begin
            info("==> Adding device '#{resource[:alias]}' to Zenoss...")
            uribase = resource[:zenossuri]
            zenosscollector = resource[:zenosscollector]
            grouppath = resource[:grouppath]
            systempath = resource[:systempath]
            locationpath = resource[:locationpath]
            serialnumber = resource[:serialnumber]
            uriext = "/DeviceLoader"
            uri = "#{uribase}#{uriext}"
            debug("The URI: #{uri}")
            s = XMLRPC::Client.new2(uri)
            out = s.call('loadDevice', _devName, _devPath,
                        tag = '',
                        serialNumber = '',   # Use zproperty inheritance
                        zSnmpCommunity = '', # ditto
                        zSnmpPort = '',      # ditto
                        zSnmpVer = '',       # ditto
                        rackSlot = 0,
                        productionState = 1000,
                        comments = "Added: #{Time.now.to_s}",
                        hwManufacturer = '', # Leaving blank, to be populated by model cycle
                        hwProductName = '',  # ditto
                        osManufacturer = '', # ditto
                        osProductName = '',  # ditto
                        locationPath = locationpath,
                        groupPaths = grouppath,
                        systemPaths = systempath,
                        statusMonitors = 'localhost',
                        performanceMonitor = 'localhost',
                        discoverProto = 'none')

            if out == 0
                info("<== result: #{out}: Successfully added device")
                renameDevice(resource[:ip], resource[:zenosstype], resource[:name])
            elsif out == 1
                err("<== result: #{out}: Device could not be added, may be it already exists (actually this should be error code '2'). Maybe there is something wrong with the Zenoss server.")
            else
                result = out.to_s
                err("<== result: Unknown return code: #{result}")
            end
        rescue XMLRPC::FaultException => e
            err('Error occurred while adding the device.')
            err('Error code:')
            err(e.faultCode)
            err('Error string:')
            err(e.faultString)
        ensure
            debug("")
        end
    end

    
    # Renames a device
    def renameDevice(_devName, _devPath, _newDevName)
        begin
            info("==> Rename the device #{_devName} to #{_newDevName}...")
            uribase = resource[:zenossuri]
            uriext = "/Devices#{_devPath}/devices/#{_devName}"
            uri = "#{uribase}#{uriext}"
            debug("The URI: #{uri}")
            s = XMLRPC::Client.new2(uri)
            out = s.call('renameDevice', _newDevName)
            debug("|| result: #{out}")
            info("<== device successfully renamed.")
            return true
        rescue RuntimeError => re
            if re.inspect =~ /HTTP-Error: 302 Moved Temporarily/
                debug("ignore 'HTTP-Error: 302 Moved Temporarily'.")
                info('<== device successfully renamed.')
                return true
            else
                err(re)
                return false
            end
        rescue Exception => e
            err('Error code:')
            err(e.faultCode)
            err('Error string:')
            err(e.faultString)
            return false
        end
    end
end
