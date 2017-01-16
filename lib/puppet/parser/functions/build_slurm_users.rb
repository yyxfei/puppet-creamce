module Puppet::Parser::Functions

  newfunction(:build_slurm_users, :type => :rvalue, :doc => "It returns the table of slurm users") do | args |
    voenv = args[0]
    queues = args[1]
    def_pool_size = args[2].to_i()
    use_std_accts = args[3]
    deps = args[4]
    
    result = Hash.new
    
    partTable = Hash.new
    queues.each do | qname, qdata |
      qdata["groups"].each do | grpname |
        unless partTable.has_key?(grpname)
          partTable[grpname] = Set.new
        end
        partTable[grpname].add(qname)
      end
    end
    
    voenv.each do | voname, vodata |
      vodata['users'].each do | user_prefix, udata |
      
        pool_size = udata.fetch('pool_size', def_pool_size)
        name_pattern = udata.fetch('name_pattern', '%<prefix>s%03<index>d')
        
        if use_std_accts
          accounts = udata['groups']
        else
          accounts = udata.fetch('accounts', nil)
          unless accounts
            raise "Missing accounts definition for #{user_prefix}"
          end
        end
        
        partSet = Set.new
        udata['groups'].each do | grpname |
          partSet.merge(partTable[grpname])
        end
        
        if pool_size > 0
        
          (0...pool_size).each do | idx |
            nameStr = sprintf(name_pattern % { :prefix => user_prefix, :index => idx })

            result["acctusr_#{nameStr}"] = Hash[
              "pool_user"     => nameStr,
              "accounts"      => accounts,
              "partitions"    => partSet.to_a(),
              "dep_resources" => deps
            ]
          
          end
        else
          # static account
          result["acctusr_#{user_prefix}"] = Hash[
              "pool_user"     => user_prefix,
              "accounts"      => accounts,
              "partitions"    => partSet.to_a(),
              "dep_resources" => deps
          ]
        end
      end
    end

    return result

  end

end
