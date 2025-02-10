#!/bin/bash -e

pushd "$(dirname "$0")" >/dev/null

ROOT="$(pwd -P)"/..

pushd "$ROOT" >/dev/null

## Checking if CHANGED is set and non-empty
if [ -n "${CHANGED+z}" ]; then
    if [ -z "$CHANGED" ]; then
        echo "Nothing here to check"
        exit 0
    fi

    SEARCH_PATHS=""
    for file in $CHANGED; do
        ext=${file##*.}
        [[ $ext == "erl" || $ext == "hrl" || $ext == "escript" ]] && SEARCH_PATHS+=" $file"
    done

else
    SEARCH_PATHS="core applications scripts"
fi

# replace FROM_MOD FROM_FUN TO_MOD TO_FUN
replace() {
    local M0=$1
    local F0=$2
    local M1=$3
    local F1=$4

    for FILE in $(grep -s -Irl $M0:$F0 $SEARCH_PATHS); do
        sed -i "s%$M0:$F0%$M1:$F1%g" "$FILE"
    done
}

# replace_call FromModule ToModule OldFun NewFun Filename
replace_call() {
    FROM="$1"
    TO="$2"
    OLD_FUN="$3"
    NEW_FUN="${3%$4}"
    FILE="$5"

    #echo "s/$FROM:$OLD_FUN/$TO:$NEW_FUN/g"
    sed -i "s%$FROM:$OLD_FUN%$TO:$NEW_FUN%g" "$FILE"
}

search_and_replace() {
    declare -a FUNS=("${!1}")
    FROM="$2"
    TO="$3"
    SUFFIX="$4"

    for FUN in "${FUNS[@]}"; do
        for FILE in $(grep -s -Irl $FROM:$FUN $SEARCH_PATHS); do
            replace_call $FROM $TO "$FUN" "$SUFFIX" "$FILE"
        done
    done
}

search_and_replace_exact() {
    declare -a FUNS=("${!1}")
    FROM=$2
    TO=$3
    TOFUN=$4

    for FUN in "${FUNS[@]}"; do
        for FILE in $(grep -s -rl "$FROM:$FUN" $SEARCH_PATHS); do
            replace_call $FROM $TO "$FUN" "$TOFUN" $FILE
        done
    done
}

replace_call_prefix() {
    FROM="$1"
    TO="$2"
    OLD_FUN="$3"
    NEW_FUN="${3#$4}"
    FILE="$5"

    #echo "s/$FROM:$OLD_FUN/$TO:$NEW_FUN/g"
    sed -i "s%$FROM:$OLD_FUN%$TO:$NEW_FUN%g" "$FILE"
}

search_and_replace_prefix() {
    declare -a FUNS=("${!1}")
    FROM="$2"
    TO="$3"
    PREFIX="$4"

    for FUN in "${FUNS[@]}"; do
        for FILE in $(grep -s -Irl $FROM:$FUN $SEARCH_PATHS); do
            replace_call_prefix $FROM $TO "$FUN" "$PREFIX" "$FILE"
        done
    done
}

replace_call_with_prefix() {
    FROM="$1"
    TO="$2"
    OLD_FUN="$3"
    NEW_FUN="$4$3"
    FILE="$5"

    #echo "s/$FROM:$OLD_FUN/$TO:$NEW_FUN/g"
    sed -i "s%$FROM:$OLD_FUN%$TO:$NEW_FUN%g" "$FILE"
}

search_and_replace_with_prefix() {
    declare -a FUNS=("${!1}")
    FROM="$2"
    TO="$3"
    PREFIX="$4"

    for FUN in "${FUNS[@]}"; do
        for FILE in $(grep -s -Irl $FROM:$FUN $SEARCH_PATHS); do
            replace_call_with_prefix $FROM $TO "$FUN" "$PREFIX" "$FILE"
        done
    done
}

# Functions moved from kz_util into more appropriately-named modules
# Run this to convert references from kz_util:* to the new module names

kz_util_to_term() {
    local fs=(shuffle_list
              to_integer
              to_float
              to_number
              to_hex
              to_hex_binary
              to_hex_char
              to_list
              to_binary
              to_atom
              to_boolean
              to_date
              to_datetime
              to_lower_binary
              to_lower_string
              to_upper_binary
              to_upper_string
              to_upper_char
              to_lower_char
              error_to_binary

              is_true
              is_false
              is_boolean
              is_ne_binary
              is_empty
              is_not_empty
              is_proplist
              identity
              always_true
              always_false
              a1hash
              floor
              ceiling
              iolist_join
              pretty_print_bytes
             )
    search_and_replace fs[@] kz_util kz_term ''
}

kz_util_to_binary() {
    local fs=(rand_hex_binary
              hexencode_binary
              from_hex_binary
              ucfirst_binary
              lcfirst_binary
              strip_binary
              strip_left_binary
              strip_right_binary
              suffix_binary
              truncate_binary
              truncate_left_binary
              truncate_right_binary
              from_hex_string
              clean_binary
              remove_white_spaces
              binary_md5
              pad_binary
              pad_binary_left
              join_binary
              binary_reverse
             )
    local special=(binary_md5 binary_reverse)
    search_and_replace             fs[@] kz_util   kz_binary _binary
    search_and_replace        special[@] kz_util   kz_binary binary_
    search_and_replace_prefix special[@] kz_binary kz_binary binary_
}

kz_util_to_time() {
    local fs=(current_tstamp
              current_unix_tstamp
              decr_timeout
              elapsed_ms
              elapsed_ms
              elapsed_s
              elapsed_s
              elapsed_us
              elapsed_us
              format_date
              format_datetime
              format_time
              gregorian_seconds_to_unix_seconds
              iso8601
              microseconds_to_seconds
              milliseconds_to_seconds
              month
              now
              now_ms
              now_s
              now_us
              pad_month
              pretty_print_datetime
              pretty_print_elapsed_s
              rfc1036
              unitfy_seconds
              unix_seconds_to_gregorian_seconds
              unix_timestamp_to_gregorian_seconds
              weekday
             )
    search_and_replace fs[@] kz_util kz_time ''
}

kz_util_to_module() {
    FROM=kz_util
    TO=kz_module
    OLD_FUN=try_load_module
    NEW_FUN=ensure_loaded

    replace "$FROM" "$OLD_FUN" "$TO" "$NEW_FUN"
}

kz_util_to_log() {
    local fs=(log_stacktrace
              put_callid
              get_callid
              find_callid
              kz_log_md_clear
              kz_log_md_put
             )
    search_and_replace fs[@] kz_util kz_log ''
}

kz_time_to_date() {
    local fs=(iso8601_date)
    local fs2=(pad_date
               pad_month
             )
    search_and_replace_exact fs[@] "kz_time" "kz_date" "to_iso8601_extended"
    search_and_replace fs2[@] "kz_time" "kz_date" ""
}

kz_json_to_kz_doc() {
    local fs=(get_public_keys
              public_fields
              private_fields
              is_private_key
             )
    search_and_replace fs[@] kz_json kz_doc ''
}

kz_json_to_kz_http() {
    local fs=(to_querystring)
    search_and_replace_with_prefix fs[@] kz_json kz_http_util json_
}

props_to_kz_http() {
    local fs=(to_querystring)
    search_and_replace_with_prefix fs[@] props kz_http_util props_
}

kapps_speech_to_kazoo_speech() {
    local fs=(create)

    local asrs=(asr_freeform
                asr_commands
               )

    search_and_replace fs[@] kapps_speech kazoo_tts ''
    search_and_replace_prefix asrs[@] kapps_speech kazoo_asr asr_
}

kapps_call_recording() {
    FROM=$1
    TO=kapps_call_recording
    for FILE in $(grep -s -Irl $FROM: $SEARCH_PATHS); do
            replace_call $FROM $TO '' '' "$FILE"
    done
}

kzd_accessors() {
    echo "  * kz_device->kzd_devices"
    kz_device_to_kzd_devices
    echo "  * kz_account->kzd_accounts"
    kz_account_to_kzd_accounts
    echo "  * kz_util->kzd_accounts"
    kz_util_to_kzd_accounts
    echo "  * kzd_webhook->kzd_webhooks"
    kzd_webhook_to_webhooks
    echo "  * kzd_voicemail_box->kzd_vmboxes"
    kzd_voicemail_box_to_kzd_vmboxes
}

kz_device_to_kzd_devices() {
    FROM=kz_device
    TO=kzd_devices
    for FILE in $(grep -s -Irl $FROM: $SEARCH_PATHS); do
        replace_call $FROM $TO '' '' "$FILE"
    done
}

kz_account_to_kzd_accounts() {
    FROM=kz_account
    TO=kzd_accounts
    for FILE in $(grep -s -Irl $FROM: $SEARCH_PATHS); do
        replace_call $FROM $TO '' '' "$FILE"
    done
}

kz_util_to_kzd_accounts() {
    FROM_MOD=kz_util
    TO_MOD=kzd_accounts

    # replace FROM_MOD FROM_FUN TO_MOD TO_FUN
    replace $FROM_MOD "is_in_account_hierarchy" $TO_MOD "is_in_account_hierarchy"
    replace $FROM_MOD "is_system_admin" $TO_MOD "is_superduper_admin"
    replace $FROM_MOD "is_account_expired" $TO_MOD "is_expired"
    replace $FROM_MOD "is_account_enabled" $TO_MOD "is_enabled"
    replace $FROM_MOD "account_update" $TO_MOD "save"
    replace $FROM_MOD "normalize_account_name" $TO_MOD "normalize_name"
}

# Functions merged from kzd_voicemail_box module into kzd_vmboxes module.
kzd_voicemail_box_to_kzd_vmboxes() {
    FROM_MOD=kzd_voicemail_box
    TO_MOD=kzd_vmboxes

    # replace FROM_MOD FROM_FUN TO_MOD TO_FUN
    replace $FROM_MOD "new" $TO_MOD "new"
    replace $FROM_MOD "type" $TO_MOD "type"
    replace $FROM_MOD "announcement_only" $TO_MOD "announcement_only"
    replace $FROM_MOD "check_if_owner" $TO_MOD "check_if_owner"
    replace $FROM_MOD "is_setup" $TO_MOD "is_setup"
    replace $FROM_MOD "mailbox_number" $TO_MOD "mailbox"
    replace $FROM_MOD "media_extension" $TO_MOD "media_extension"
    replace $FROM_MOD "notification_emails" $TO_MOD "notify_email_addresses"
    replace $FROM_MOD "owner_id" $TO_MOD "owner_id"
    replace $FROM_MOD "pin" $TO_MOD "pin"
    replace $FROM_MOD "pin_required" $TO_MOD "require_pin"
    replace $FROM_MOD "set_notification_emails" $TO_MOD "set_notify_email_addresses"
    replace $FROM_MOD "skip_envelope" $TO_MOD "skip_envelope"
    replace $FROM_MOD "skip_greeting" $TO_MOD "skip_greeting"
    replace $FROM_MOD "skip_instructions" $TO_MOD "skip_instructions"
    replace $FROM_MOD "timezone" $TO_MOD "timezone"
}

kzd_webhook_to_webhooks() {
    FROM='kzd_webhook:'
    TO='kzd_webhooks:'
    for FILE in $(grep -s -Irl $FROM: $SEARCH_PATHS); do
        replace_call $FROM $TO '' '' "$FILE"
    done
}

amqp_util_to_kz_amqp_util() {
    FROM="amqp_util"
    TO="kz_amqp_util"
    for FILE in $(grep -s -Irl $FROM: $SEARCH_PATHS); do
        sed -i -e "s%\b$FROM%$TO%g" "$FILE"
    done
}

kz_includes() {
    INCLUDES=(kz_databases.hrl
              kz_log.hrl
              kz_types.hrl
             )
    FROM=kazoo/include
    TO=kazoo_stdlib/include

    for FILE in $(grep -s -Irl $FROM/ $SEARCH_PATHS); do
        for INCLUDE in "${INCLUDES[@]}"; do
            sed -i "s%$FROM/$INCLUDE%$TO/$INCLUDE%g" "$FILE"
        done
    done
}

dedupe() {
    replace crossbar_util get_account_doc kz_account fetch

    replace       kz_util get_account_realm kz_account fetch_realm
    replace crossbar_util get_account_realm kz_account fetch_realm

    replace  kapps_util get_account_name kz_account fetch_name
    replace kz_services account_name     kz_account fetch_name

    replace kapps_util get_event_type kz_api get_event_type
}

replace_types() {
    local MODULE="$1"
    local GREP_PATTERN="$2"
    local PERL_PATTERN="$3"
    local REPLACE_TO="$4"
    for FILE in $(grep -s -Plr --include=*.erl --include=*.hrl --include=*.escript --exclude="$MODULE.erl" "$GREP_PATTERN" $SEARCH_PATHS); do
        perl -pi -e "s/$PERL_PATTERN/$REPLACE_TO/g" "$FILE"
    done
}

change_to_module_type() {
    local MODULE="$1"
    declare -a TYPES_ARR=("${!2}")

    local TYPES="$(echo -n ${TYPES_ARR[@]} | sed -r 's/ +/\|/g; s/\|*$//g')"

    local GREP_PATTERN="(:{0}(:{2})|([ ,([{>]))(?<!\-spec |?<!\-callback )($TYPES) *\("
    local PERL_PATTERN="(:{0}(:{2})|([ ,([{>]))(?<!\-spec |?<!\-callback )($TYPES)(\(\)|\(([a-zA-Z_]|\[\])+\(?\))"
    local REPLACE_TO="\1$MODULE:\4\5"

    replace_types "$MODULE" "$GREP_PATTERN" "$PERL_PATTERN" "$REPLACE_TO"
}

change_kz_timeout() {
    local GREP_PATTERN="kz_timeout"
    local PERL_PATTERN="kz_timeout"

    replace_types "kz_types" "$GREP_PATTERN" "$PERL_PATTERN" "timeout"
}

removing_kz_prefix_from_types() {
    local MODULE="$1"
    declare -a TYPES=("${!2}")

    K_TYPES="$(echo -n ${TYPES[@]} | grep -Eo 'kz_[a-z_]+' | tr '\n' ' ' | sed -r 's/ +/\|/g; s/\|*$//g')"
    WITHOUT_K="$(echo -n $K_TYPES | sed 's/kz_//g')"

    local GREP_PATTERN="$MODULE:$K_TYPES"
    local PERL_PATTERN="$MODULE:kz_($WITHOUT_K)"
    local REPLACE_TO="$MODULE:\1"

    replace_types "$MODULE" "$GREP_PATTERN" "$PERL_PATTERN" "$REPLACE_TO"
}

kz_type_modules() {
    local kz_types=(mail_message_body
                    dict
                    kz_ip_list
                    sup_child_spec
                    sup_child_specs
                    sup_start_flags
                    sup_init_ret
                    sup_child_id
                    sup_startchild_err
                    sup_startchild_ret
                    startlink_err
                    startlink_ret
                    startapp_ret
                    call_from
                    gen_server_timeout
                    handle_call_ret
                    handle_call_ret_state
                    handle_cast_ret
                    handle_cast_ret_state
                    handle_info_ret
                    handle_info_ret_state
                    handle_fsm_ret
                    handle_sync_event_ret
                    server_ref
                    gen_server_name
                    gen_server_option
                    gen_server_options
                    xml_attrib_name
                    xml_attrib_value
                    xml_attrib
                    xml_attribs
                    xml_el
                    xml_els
                    xml_text
                    xml_texts
                    xml_thing
                    xml_things
                    whapp_info
                    kapps_info
#                    media_server
                    media_serve
                    )
    local kz_term=(text
                   atoms
                   pids
                   references
                   kz_proplist_key
                   kz_proplist_value
                   kz_proplist_property
                   kz_proplist
                   kz_proplists
                   kz_proplist_kv
                   pid_ref
                   pid_refs
                   api_pid_ref
                   api_pid_refs
                   api_terms
                   api_binary
                   api_ne_binary
                   api_ne_binaries
                   api_binaries
                   api_object
                   api_objects
                   api_boolean
                   api_atom
                   api_atoms
                   api_string
                   api_reference
                   api_pid
                   api_list
                   api_number
                   api_integer
                   api_pos_integer
                   api_non_neg_integer
                   api_float
                   kz_deeplist
                   kz_std_return
                   kz_jobj_return
                   kz_jobjs_return
                   ne_binary
                   ne_binaries
                   binaries
                   strings
                   integers
                   functions
                   )
    local kz_time=(kz_now
                   kz_year
                   kz_month
                   kz_day
                   kz_hour
                   kz_minute
                   kz_second
                   kz_daynum
                   kz_weeknum
                   kz_date
                   kz_time
                   kz_datetime
                   kz_iso_week
                   gregorian_seconds
                   unix_seconds
                   api_seconds
                   )
    local kz_node=(kz_node
                   kz_nodes
                  )
    echo "  * ensuring core types migration"
    change_to_module_type "kz_types" kz_types[@]
    echo "  * ensuring term types migration"
    change_to_module_type "kz_term" kz_term[@]
    echo "  * ensuring time types migration"
    change_to_module_type "kz_time" kz_time[@]
    echo "  * ensuring kz_node/kz_nodes migration"
    change_to_module_type "kz_types" kz_node[@]
    echo "  * using built in kz_timeout type"
    change_kz_timeout
    echo "  * removing kz_ prefix from kz_types"
    removing_kz_prefix_from_types "kz_types" kz_types[@]
    echo "  * removing kz_ prefix from kz_term"
    removing_kz_prefix_from_types "kz_term" kz_term[@]
    echo "  * removing kz_ prefix from kz_time"
    removing_kz_prefix_from_types "kz_time" kz_time[@]
}

kapps_util_moves() {
    replace "kapps_util" "amqp_pool_send" "kz_amqp_worker" "cast"
    replace "kapps_util" "amqp_pool_collect" "kz_amqp_worker" "call_collect"
    replace "kapps_util" "amqp_pool_request_custom" "kz_amqp_worker" "call_custom"
    replace "kapps_util" "amqp_pool_request" "kz_amqp_worker" "call"
    replace "kapps_util" "is_account_db" "kzs_util" "is_account_db"
    replace "kapps_util" "is_account_mod" "kzs_util" "is_account_mod"
    replace "kapps_util" "is_account_yod" "kzs_util" "is_account_yod"
}

kz_util_props() {
    replace 'kz_util' 'uniq' 'props' 'unique'
}

kz_util_uri() {
    replace 'kz_util' 'uri_' 'kz_http_util' 'url'
    replace 'kz_util' 'uri' 'kz_http_util' 'uri'
    replace 'kz_util' 'resolve_uri' 'kz_http_util' 'resolve_uri'
}

kz_util_processes() {
    local fs=(runs_in
              spawn
              spawn_link
              spawn_monitor
              set_startup
              startup
             )
    search_and_replace fs[@] kz_util kz_process ''
}

kz_util_application() {
    local fs=(calling_app
              calling_app_version
              calling_process
              get_app
              application_version
             )
    search_and_replace fs[@] kz_util kz_application ''
}

kz_util_os() {
    local fs=(write_file
              rename_file
              delete_file
              delete_dir
              make_dir
             )
    search_and_replace fs[@] kz_util kz_os ''
}

kz_util_version() {
    local fs=(kazoo_version
              bin_usage
              mem_usage
              write_pid
             )
    search_and_replace fs[@] kz_util kapps_util ''
}

kz_util_nodes() {
    local fs=(node_name
              node_hostname
             )
    search_and_replace fs[@] kz_util kz_nodes ''

    }

kz_util_api() {
    replace 'kz_util' 'get_event_type' 'kz_api' 'event_type'
}

kz_util_format_ids() {
    replace 'kz_util' 'format_account_id' 'kzs_util' 'format_account_id'
    replace 'kz_util' 'format_account_mod_id' 'kzs_util' 'format_account_mod_id'
    replace 'kz_util' 'format_account_db' 'kzs_util' 'format_account_db'
    replace 'kz_util' 'format_account_modb' 'kzs_util' 'format_account_modb'
    replace 'kz_util' 'format_resource_selectors_id' 'kzs_util' 'format_resource_selectors_id'
    replace 'kz_util' 'format_resource_selectors_db' 'kzs_util' 'format_resource_selectors_db'
    replace 'kz_util' 'account_format' 'kzs_util' 'account_format'

    for FILE in $(grep -s -rPl "kzs_util:format_account_id(.*, \'encoded\')" $SEARCH_PATHS); do
        sed -ri "s#kzs_util:format_account_id[(](.+), 'encoded'[)]#kzs_util:format_account_db(\1)#g" "$FILE"
    done

    for FILE in $(grep -s -rPl "kzs_util:format_account_id(.*, \'raw\')" $SEARCH_PATHS); do
        sed -ri "s#kzs_util:format_account_id[(](.+), 'raw'[)]#kzs_util:format_account_id(\1)#g" "$FILE"
    done
}

rename_knm_to_knums() {
    for FILE in $(grep -s -Irl --exclude-dir='.git' kazoo_numbers $SEARCH_PATHS); do
        sed -i "s/kazoo_numbers/kazoo_numbers/g" "$FILE"
    done
}

cb_context_rename() {
    for FILE in $(grep -s -Irl --exclude-dir='.git' "cb_context:account_db" $SEARCH_PATHS); do
        sed -i 's/cb_context:db_name(/cb_context:db_name(/g' "$FILE"
    done
}

kz_services_reseller_id() {
    replace "kzd_accounts" "reseller_id" "kz_services_reseller" "get_id"
}

kz_term_kz_math() {
    local fs=(a1hash
              floor
              ceiling
              xnor
             )
    search_and_replace fs[@] kz_term kz_math ''
}

echo "ensuring kz_term is used"
kz_util_to_term
echo "ensuring kz_binary is used"
kz_util_to_binary
echo "ensuring kz_time is used"
kz_util_to_time
echo "ensuring kz_module is used"
kz_util_to_module
echo "ensuring kz_time -> kz_date migration is performed"
kz_time_to_date
echo "ensuring kz_json:public/private are moved to kz_doc"
kz_json_to_kz_doc
echo "ensuring kz_json to_querystring is moved to kz_http_util"
kz_json_to_kz_http
echo "ensuring props to_querystring is moved to kz_http_util"
props_to_kz_http
echo "ensuring kapps_speech to kazoo_speech"
kapps_speech_to_kazoo_speech
echo "ensuring kz_media_recording to kapps_call_recording"
kapps_call_recording "kz_media_recording"
echo "ensuring kzc_recording to kapps_call_recording"
kapps_call_recording "kzc_recording"
echo "ensuring includes from kazoo are moved to kazoo_stdlib"
kz_includes
echo 'ensuring utility calls are not duplicated all over the place'
dedupe
echo "ensuring kz_types migration to module is performed"
kz_type_modules
echo "updating kazoo document accessors"
kzd_accessors
echo "updating amqp_util to kz_amqp_util"
amqp_util_to_kz_amqp_util
echo "moving kapps_util functions  to better modules"
kapps_util_moves
echo "updating uniq usage to props module"
kz_util_props
echo "updating URI-related functions to kz_http_util"
kz_util_uri
echo "ensuring kz_log is used"
kz_util_to_log
echo "ensuring spawning is in kz_process"
kz_util_processes
echo "ensuring Erlang app stuff is moved"
kz_util_application
echo "ensuring AMQP payload event_type is moved"
kz_util_api
echo "ensuring file stuff is moved"
kz_util_os
echo "ensuring KAZOO version is moved"
kz_util_version
echo "ensuring kazoo_numbers is renamed to kazoo_numbers"
rename_knm_to_knums
echo "formatting account/resource ids to dbs moved to kzs_util"
kz_util_format_ids
echo "cb_context account_db to db_name"
cb_context_rename
echo "use kz_services_reseller to find reseller_id"
kz_services_reseller_id
echo "move math-y functions"
kz_term_kz_math

popd >/dev/null
popd >/dev/null
