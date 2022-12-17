complete -F _service_tool main.sh
_service_tool()
{    COMPREPLY=()
   local cur=${COMP_WORDS[COMP_CWORD]}
   local cmd=${COMP_WORDS[COMP_CWORD-1]}    
   case $cmd in
       'main.sh')
       COMPREPLY=( $(compgen -W 'init host azkaban canal es flink flume hadoop hbase hive jdk kafka kibana mvn maxwell mysql nginx phoenix redis scala spark sqoop zookeeper ssh presto kylin' -- $cur ) )
       ;;
       esac
    return 0
}

