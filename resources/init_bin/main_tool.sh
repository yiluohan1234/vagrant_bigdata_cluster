complete -F _main_tool main
_main_tool()
{
    COMPREPLY=()
    local cur=${COMP_WORDS[COMP_CWORD]}
    local cmd=${COMP_WORDS[COMP_CWORD-1]}
    case $cmd in
        'main')
        COMPREPLY=( $(compgen -W 'f1 f2 f3 lg db lg_init db_init init cluster' -- $cur ) )
        ;;

        'f1')
        COMPREPLY=( $(compgen -W 'start stop' -- $cur ) )
        ;;

        'f2')
        COMPREPLY=( $(compgen -W 'start stop' -- $cur ) )
        ;;

        'f3')
        COMPREPLY=( $(compgen -W 'start stop' -- $cur ) )
        ;;

        'cluster')
        COMPREPLY=( $(compgen -W 'start stop' -- $cur ) )
        ;;
    esac
    return 0
}

