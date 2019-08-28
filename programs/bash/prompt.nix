{ pkgs, lib, ... }:

let
  # originally generated by prompt_variables
  colors = import ./colors.nix;
  host = pkgs.callPackage ../../hosts { };
  mkFunction = (pkgs.callPackage ./functions.nix { }).mkFunction;
  variables = host.bash.prompt;
in
{
  inherit variables;

  functions = "
    pre_dynamic_prompt (){
      export LAST_CODE=\"$?\"
      history -a
    }

    dynamic_prompt (){
      #local TASK_COUNT=\"\"
      #if hash task 2>/dev/null; then
      #  TASK_COUNT=\"$(task +in +PENDING count) \"
      #fi
      COLOR_AT=\"\"
      case $LAST_CODE in
        0) COLOR_AT=\"${colors.BRIGHT_BLUE}\" ;;
        1) COLOR_AT=\"${colors.BRIGHT_RED}\" ;;
        *) COLOR_AT=\"${colors.YELLOW}\" ;;
      esac


      if [ ${variables.PROMPT_INCL_USER} = true ]; then
        if [[ -n \"\${IS_NIX_SHELL}\" ]]; then
          MUSER=\"\"
        elif [[ \"$(whoami)\" == \"stites\" ]]; then
          MUSER=\"\"
        else
          MUSER=\"$(whoami)\"
        fi
        BASE=\"${variables.PROMPT_USER_COLOR}\${MUSER}\${COLOR_AT}@${variables.PROMPT_HOST_COLOR}\\h\"
      else
        #shellcheck disable=SC1117
        BASE=\"\${COLOR_AT}@${variables.PROMPT_HOST_COLOR}\\h\"
      fi

      SEP=\"${variables.PROMPT_SEP_COLOR}::\"

      ENDING=\"\"
      GBRANCH=\"$(find_git_branch)\"

      if [ ! -z \"\${GBRANCH}\" ]; then
        #shellcheck disable=SC1117
        ENDING=\"${variables.PROMPT_PATH_COLOR_GIT}\\W${variables.PROMPT_BRANCH_COLOR_GIT}#_(\${GBRANCH})${colors.RED}$(find_git_dirty)\"
      else
        #shellcheck disable=SC1117
        ENDING=\"${variables.PROMPT_PATH_COLOR}\\W\"
      fi

      if [ ! -z \"\${PYENV_VERSION}\" ]; then
        ENVS=\"$PYENV_VERSION\"
      else
        ENVS=\"\"
      fi

      if [ ! -z \"\${IN_NIX_SHELL}\" ]; then
        ENVS=\"(nix) $ENVS\"
      else
        ENVS=\"$ENVS\"
      fi

      # looks like we could just invoke functions in PS1 itself without having to use the PROMPT_COMMAND
      export PS1=\"\${ENVS}\${BASE}\${SEP}\${ENDING} ${colors.RESET}\"
    }
    ";

  initConfig = ''
    if ! [[ $PROMPT_COMMAND == "pre_dynamic_prompt; "* ]]; then
      PROMPT_COMMAND="pre_dynamic_prompt; $PROMPT_COMMAND"

      if [[ $PROMPT_COMMAND != *"dynamic_prompt; " ]]; then
        case $PROMPT_COMMAND in
          *";"|*"; ") PROMPT_COMMAND="$PROMPT_COMMAND dynamic_prompt; " ;;
          *)          PROMPT_COMMAND="$PROMPT_COMMAND; dynamic_prompt; " ;;
        esac
      else
        #shellcheck disable=SC1117
        export PS1="[\u@\h:\W]\$ "
      fi
    else
      #shellcheck disable=SC1117
      export PS1="[\u@\h:\W]\$ "
    fi
  '';
}


