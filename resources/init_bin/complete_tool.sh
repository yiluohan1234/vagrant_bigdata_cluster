complete -F _service_tool bigstart
_service_tool()
{    COMPREPLY=()
   local cur=${COMP_WORDS[COMP_CWORD]}
   local cmd=${COMP_WORDS[COMP_CWORD-1]}    
   case $cmd in
       'bigstart')
       COMPREPLY=( $(compgen -W 'ranger atlas solr kylin presto dfs yarn hdp spark zookeeper flink hbase kafka kibana elasticsearch redis logger hive maxwell canal azkaban superset' -- $cur ) )
       ;;

       'ranger')
       COMPREPLY=( $(compgen -W 'start stop' -- $cur ) )
       ;;

       'atlas')
       COMPREPLY=( $(compgen -W 'start stop' -- $cur ) )
       ;;

       'solr')
       COMPREPLY=( $(compgen -W 'start stop restart status' -- $cur ) )
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

       'hive')
       COMPREPLY=( $(compgen -W 'start stop status restart' -- $cur ) )
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
       COMPREPLY=( $(compgen -W 'start stop status restart' -- $cur ) )
       ;;

       esac
    return 0
}

