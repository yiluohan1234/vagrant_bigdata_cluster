complete -F _service_tool bigstart
_service_tool()
{    COMPREPLY=()
   local cur=${COMP_WORDS[COMP_CWORD]}
   local cmd=${COMP_WORDS[COMP_CWORD-1]}    
   case $cmd in
       'bigstart')
       COMPREPLY=( $(compgen -W 'kylin presto dfs yarn hdp spark zookeeper flink hbase kafka kibana elasticsearch redis logger hiveserver hivemetastore maxwell canal azkaban superset' -- $cur ) )
       ;;

       'kylin')
       COMPREPLY=( $(compgen -W 'start stop' -- $cur ) )
       ;;

       'presto')
       COMPREPLY=( $(compgen -W 'start stop' -- $cur ) )
       ;;
    
       'dfs')
       COMPREPLY=( $(compgen -W 'start stop format restart' -- $cur ) )
       ;;

       'yarn')
       COMPREPLY=( $(compgen -W 'start stop restart' -- $cur ) )
       ;;
    

       'hdp')
       COMPREPLY=( $(compgen -W 'start stop format restart' -- $cur ) )
       ;;
    
       'spark')
       COMPREPLY=( $(compgen -W 'start stop' -- $cur ) )
       ;;
 
       'zookeeper')
       COMPREPLY=( $(compgen -W 'start stop status' -- $cur ) )
       ;;

       'flink')
       COMPREPLY=( $(compgen -W 'start stop' -- $cur ) )
       ;;

       'hbase')
       COMPREPLY=( $(compgen -W 'start stop' -- $cur ) )
       ;;

       'kafka')
       COMPREPLY=( $(compgen -W 'start stop' -- $cur ) )
       ;;

       'kibana')
       COMPREPLY=( $(compgen -W 'start stop status' -- $cur ) )
       ;;

       'elasticsearch')
       COMPREPLY=( $(compgen -W 'start stop restart' -- $cur ) )
       ;;

       'redis')
       COMPREPLY=( $(compgen -W 'start stop restart' -- $cur ) )
       ;;

       'logger')
       COMPREPLY=( $(compgen -W 'start stop' -- $cur ) )
       ;;

       'hiveserver')
       COMPREPLY=( $(compgen -W 'start stop status' -- $cur ) )
       ;;
       'hivemetastore')
       COMPREPLY=( $(compgen -W 'start stop status' -- $cur ) )
       ;;


       'maxwell')
       COMPREPLY=( $(compgen -W 'start stop status' -- $cur ) )
       ;;

       'canal')
       COMPREPLY=( $(compgen -W 'start stop' -- $cur ) )
       ;;

       'azkaban')
       COMPREPLY=( $(compgen -W 'start stop' -- $cur ) )
       ;;

       'superset')
       COMPREPLY=( $(compgen -W 'start stop status' -- $cur ) )
       ;;










       esac
    return 0
}

