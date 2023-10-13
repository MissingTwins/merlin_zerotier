#!/bin/sh

source /jffs/scripts/mylib.sh

# ---------------------------------------------------

task_body1=$(cru l)

# ---------------------------------------------------

# -r
#
#    Backslash does not act as an escape character.  
#    The backslash is considered to be part of the line.  
#    In particular, a backslash-newline pair may not be used as a line continuation.

cat /jffs/scripts/myservices.sh | while IFS=  read -r line ; do 
    
    #if [[ "$line" =~ ^cru[[:space:]]+a[[:space:]]+(.+)[[:space:]]+\"(.+)\" ]]; then
    #    cru_name="${BASH_REMATCH[1]}"
    #    cru_body="${BASH_REMATCH[2]}"
    cru_name=$(echo "$line" | grep -iPo '^\s*cru\s+a\s+\K[\w.-]+' )
    cru_body=$(echo "$line" | grep -iPo '^\s*cru\s+a\s+[\w.-]+\s+\"?\K[^"]+' )
    if [ -n "$cru_name" ] && [ -n "$cru_body" ] ;then
        
        #echo "${cru_name} | ${cru_body}"
        tst=$(echo "$task_body1" | grep -i "${cru_name}")
        if [ "$?" -eq 0 ];then
            echo "Found OnDuty Task $tst"
            tst2=$(echo "$tst" | grep -iPo "^(?:[*\/\d]+\s+){5}")
            if [ "$?" -ne 0 ];then
                cru d "${cru_name}"
                cru a "${cru_name}" "${cru_body}"
                sysLOG "Found malformed and reconstructed: ${cru_body}" error
            fi
            echo ""
        fi
        
    fi

done

