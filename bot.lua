package.path = package.path .. ';.luarocks/share/lua/5.2/?.lua'
.. ';.luarocks/share/lua/5.2/?/init.lua'
package.cpath = package.cpath .. ';.luarocks/lib/lua/5.2/?.so'

tdcli = dofile('tdcli.lua')
redis = (loadfile "./libs/redis.lua")()
serpent = require('serpent')
serp = require 'serpent'.block


--tdcli = dofile('tdcli.lua')
--redis = dofile('./libs/redis.lua')
--local redis = require 'redis'
--redis = (loadfile "./libs/redis.lua")()
--JSON = require('dkjson')
--redis = redis.connect('127.0.0.1', 6379)
--serpent = require('serpent')
--JSON = require('dkjson')
--serpent = require('serpent')
--redis = (loadfile "./libs/redis.lua")()
redis = require('redis')


sudo_users = {
  90285047,
  0
}


function is_sudo(msg)
  local var = false
  for v,user in pairs(sudo_users) do
    if user == msg.sender_user_id_ then
      var = true
    end
  end
  return var
end

function is_normal(msg)
  local chat_id = msg.chat_id_
  local user_id = msg.sender_user_id_
  local mutel = redis:sismember('muteusers:'..chat_id,user_id)
  if mutel then
    return true
  end
  if not mutel then
    return false
  end
end
-- function owner
function is_owner(msg)
  local var = false
  local chat_id = msg.chat_id_
  local user_id = msg.sender_user_id_
  local group_mods = redis:get('owners:'..chat_id)
  if group_mods == tostring(user_id) then
    var = true
  end
  for v, user in pairs(sudo_users) do
    if user == user_id then
      var = true
    end
  end
  return var
end
--- function promote
function is_mod(msg)
  local var = false
  local chat_id = msg.chat_id_
  local user_id = msg.sender_user_id_
  if redis:sismember('mods:'..chat_id,user_id) then
    var = true
  end
  if  redis:get('owners:'..chat_id) == tostring(user_id) then
    var = true
  end
  for v, user in pairs(sudo_users) do
    if user == user_id then
      var = true
    end
  end
  return var
end
-- Print message format. Use serpent for prettier result.
function vardump(value, depth, key)
  local linePrefix = ''
  local spaces = ''

  if key ~= nil then
    linePrefix = key .. ' = '
  end

  if depth == nil then
    depth = 0
  else
    depth = depth + 1
    for i=1, depth do
      spaces = spaces .. '  '
    end
  end

  if type(value) == 'table' then
    mTable = getmetatable(value)
    if mTable == nil then
      print(spaces .. linePrefix .. '(table) ')
    else
      print(spaces .. '(metatable) ')
      value = mTable
    end
    for tableKey, tableValue in pairs(value) do
      vardump(tableValue, depth, tableKey)
    end
  elseif type(value)  == 'function' or
    type(value) == 'thread' or
    type(value) == 'userdata' or
    value == nil then 
    print(spaces .. tostring(value))
  elseif type(value)  == 'string' then
    print(spaces .. linePrefix .. '"' .. tostring(value) .. '",')
  else
    print(spaces .. linePrefix .. tostring(value) .. ',')
  end
end

-- Print callback
function dl_cb(arg, data)
end


local function setowner_reply(extra, result, success)
  t = vardump(result)
  local msg_id = result.id_
  local user = result.sender_user_id_
  local ch = result.chat_id_
  redis:del('owners:'..ch)
  redis:set('owners:'..ch,user)
  tdcli.sendText(result.chat_id_, 0, 0, 1, nil, '_User_ *['..user..']* _Added As Owner_', 1, 'md')
  print(user)
end

local function deowner_reply(extra, result, success)
  t = vardump(result)
  local msg_id = result.id_
  local user = result.sender_user_id_
  local ch = result.chat_id_
  redis:del('owners:'..ch)
  tdcli.sendText(result.chat_id_, 0, 0, 1, nil, '_User_ *['..user..']* _Removed From Owner_', 1, 'md')
  print(user)
end


local function setmod_reply(extra, result, success)
vardump(result)
local msg = result.id_
local user = result.sender_user_id_
local chat = result.chat_id_
redis:sadd('mods:'..chat,user)
tdcli.sendText(result.chat_id_, 0, 0, 1, nil, '_User_ *['..user..']* _Has Been Promoted*', 1, 'md')
end

local function remmod_reply(extra, result, success)
vardump(result)
local msg = result.id_
local user = result.sender_user_id_
local chat = result.chat_id_
redis:srem('mods:'..chat,user)
tdcli.sendText(result.chat_id_, 0, 0, 1, nil, '_User_ *['..user..']* _Has Been Demoted_', 1, 'md')
end

function kick_reply(extra, result, success)
  b = vardump(result)
  tdcli.changeChatMemberStatus(result.chat_id_, result.sender_user_id_, 'Kicked')
  tdcli.sendText(result.chat_id_, 0, 0, 1, nil, '_User_ *['..result.sender_user_id_..']* _Has Been Kicked_', 1, 'md')
end

function ban_reply(extra, result, success)
  b = vardump(result)
  tdcli.changeChatMemberStatus(result.chat_id_, result.sender_user_id_, 'Banned')
  tdcli.sendText(result.chat_id_, 0, 0, 1, nil, '_User_ *['..result.sender_user_id_..']* _Banned_', 1, 'md')
end


local function setmute_reply(extra, result, success)
  vardump(result)
  redis:sadd('muteusers:'..result.chat_id_,result.sender_user_id_)
  tdcli.sendText(result.chat_id_, 0, 0, 1, nil, '_User_ *['..result.sender_user_id_..']* _Added To Muted User List_', 1, 'md')
end

local function demute_reply(extra, result, success)
  vardump(result)
  redis:srem('muteusers:'..result.chat_id_,result.sender_user_id_)
  tdcli.sendText(result.chat_id_, 0, 0, 1, nil, '_User_ *['..result.sender_user_id_..']* _Removed From Muted User List_', 1, 'md')
end



function tdcli_update_callback(data)
  vardump(data)

  if (data.ID == "UpdateNewMessage") then
    local msg = data.message_
    local input = msg.content_.text_
    local chat_id = msg.chat_id_
    local user_id = msg.sender_user_id_
    local reply_id = msg.reply_to_message_id_
    vardump(msg)
    if msg.content_.ID == "MessageText" then
      if input == "ping" then
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '`pong`', 1, 'md')

      end
      if input == "PING" then
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '<b>PONG</b>', 1, 'html')
      end
      if input:match("^[#!/][Ii][Dd]$") then
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '<b>Chat ID:</b> <code>'..string.sub(chat_id, 5,14)..'</code>\n<b>Your ID:</b> <code>'..user_id..'</code>', 1, 'html')
      end

      if input:match("^[#!/][Pp][Ii][Nn]$") and reply_id and is_owner(msg) then
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '<b>Done!</b>', 1, 'html')
        tdcli.pinChannelMessage(chat_id, reply_id, 1)
      end

      if input:match("^[#!/][Uu][Nn][Pp][Ii][Nn]$") and reply_id and is_owner(msg) then
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '<b>Done!</b>', 1, 'html')
        tdcli.unpinChannelMessage(chat_id, reply_id, 1)
      end


      -----------------------------------------------------------------------------------------------------------------------------
      if input:match('^[!#/]([Ss]etowner)$') and is_owner(msg) and msg.reply_to_message_id_ then
        tdcli.getMessage(chat_id,msg.reply_to_message_id_,setowner_reply,nil)
      end
      if input:match('^[!#/]([Rr]emowner)$') and is_sudo(msg) and msg.reply_to_message_id_ then
        tdcli.getMessage(chat_id,msg.reply_to_message_id_,deowner_reply,nil)
      end

      if input:match('^[!#/]([Oo]wner)$') then
        local hash = 'owners:'..chat_id
        local owner = redis:get(hash)
        if owner == nil then
          tdcli.sendText(chat_id, 0, 0, 1, nil, '_No Owner In This Group_', 1, 'md')
        end
        local owner_list = redis:get('owners:'..chat_id)
        text85 = 'SuperGroup Owner Is *['..owner_list..']*'
        tdcli.sendText(chat_id, 0, 0, 1, nil, text85, 1, 'md')
      end
      if input:match('^[/!#]setowner (.*)') and not input:find('@') and is_sudo(msg) then
        redis:del('owners:'..chat_id)
        redis:set('owners:'..chat_id,input:match('^[/!#]setowner (.*)'))
        tdcli.sendText(chat_id, 0, 0, 1, nil, '_User_ *['..input:match('^[/!#]setowner (.*)')..']* _Added As Owner_', 1, 'md')
      end

      if input:match('^[/!#]setowner (.*)') and input:find('@') and is_owner(msg) then
        function Inline_Callback_(arg, data)
          redis:del('owners:'..chat_id)
          redis:set('owners:'..chat_id,input:match('^[/!#]setowner (.*)'))
          tdcli.sendText(chat_id, 0, 0, 1, nil, '_User_ *['..input:match('^[/!#]setowner (.*)')..']* _Added As Owner_', 1, 'md')
        end
        tdcli_function ({ID = "SearchPublicChat",username_ =input:match('^[/!#]setowner (.*)')}, Inline_Callback_, nil)
      end


      if input:match('^[/!#]remowner (.*)') and is_sudo(msg) then
        redis:del('owners:'..chat_id)
        tdcli.sendText(chat_id, 0, 0, 1, nil, '_User_ *['..input:match('^[/!#]remowner (.*)')..']* _Removed From Owner_', 1, 'md')
      end
      -----------------------------------------------------------------------------------------------------------------------
      if input:match('^[/!#]promote') and is_sudo(msg) and msg.reply_to_message_id_ then
tdcli.getMessage(chat_id,msg.reply_to_message_id_,setmod_reply,nil)
end
if input:match('^[/!#]demote') and is_sudo(msg) and msg.reply_to_message_id_ then
tdcli.getMessage(chat_id,msg.reply_to_message_id_,remmod_reply,nil)
end
			
			sm = input:match('^[/!#]promote (.*)')
if sm and is_sudo(msg) then
  redis:sadd('mods:'..chat_id,sm)
  tdcli.sendText(chat_id, 0, 0, 1, nil, '_User_ *['..sm..']* _Has Been Promoted_', 1, 'md')
end

dm = input:match('^[/!#]demote (.*)')
if dm and is_sudo(msg) then
  redis:srem('mods:'..chat_id,dm)
  tdcli.sendText(chat_id, 0, 0, 1, nil, '_User_ *['..dm..']* _Has Been Demoted_', 1, 'md')
end

if input:match('^[/!#]modlist') then
if redis:scard('mods:'..chat_id) == 0 then
tdcli.sendText(chat_id, 0, 0, 1, nil, '_No Moderators In This Group_', 1, 'md')
end
local text = "*Group Moderators:*\n"
for k,v in pairs(redis:smembers('mods:'..chat_id)) do
text = text.."_"..k.."_ - *"..v.."*\n"
end
tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
end
      ---------------------------------------------------------------------------------------------------------------------------------
      if input:match("^[#!/][Aa]dd$") and is_sudo(msg) then
        redis:sadd('groups',chat_id)
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '_Group Has Been Added_', 1, 'md')
      end
      -------------------------------------------------------------------------------------------------------------------------------------------
      if input:match("^[#!/][Rr]em$") and is_sudo(msg) then
        redis:srem('groups',chat_id)
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '_Group Has Been Removed_', 1, 'md')
      end
      -----------------------------------------------------------------------------------------------------------------------------------------------
      -----------------------------------------------------------------------
      if input:match('^[!#/](kick)$') and is_mod(msg) then
        tdcli.getMessage(chat_id,reply,kick_reply,nil)
      end

      if input:match('^[!#/]kick (.*)') and not input:find('@') and is_mod(msg) then
        tdcli.sendText(chat_id, 0, 0, 1, nil, '_User_ *['..input:match('^[!#/]kick (.*)')..']* _Has Been Kicked_', 1, 'md')
        tdcli.changeChatMemberStatus(chat_id, input:match('^[!#/]kick (.*)'), 'Kicked')
      end

      if input:match('^[!#/]kick (.*)') and input:find('@') and is_mod(msg) then
        function Inline_Callback_(arg, data)
          tdcli.sendText(chat_id, 0, 0, 1, nil, '_User_ *['..input:match('^[!#/]kick (.*)')..']* _Has Been Kicked_', 1, 'md')
          tdcli.changeChatMemberStatus(chat_id, data.id_, 'Kicked')
        end
        tdcli_function ({ID = "SearchPublicChat",username_ =input:match('^[!#/]kick (.*)')}, Inline_Callback_, nil)
      end
      --------------------------------------------------------
      ----------------------------------------------------------
      if input:match('^[/!#]muteuser') and is_mod(msg) and msg.reply_to_message_id_ then
        redis:set('tbt:'..chat_id,'yes')
        tdcli.getMessage(chat_id,msg.reply_to_message_id_,setmute_reply,nil)
      end
      if input:match('^[/!#]unmuteuser') and is_mod(msg) and msg.reply_to_message_id_ then
        tdcli.getMessage(chat_id,msg.reply_to_message_id_,demute_reply,nil)
      end
      mu = input:match('^[/!#]muteuser (.*)')
      if mu and is_mod(msg) then
        redis:sadd('muteusers:'..chat_id,mu)
        redis:set('tbt:'..chat_id,'yes')
        tdcli.sendText(chat_id, 0, 0, 1, nil, '_User_ *['..mu..']* _Added To Muted User List_', 1, 'md')
      end
      umu = input:match('^[/!#]unmuteuser (.*)')
      if umu and is_mod(msg) then
        redis:srem('muteusers:'..chat_id,umu)
        tdcli.sendText(chat_id, 0, 0, 1, nil, '_User_ *['..umu..']* _Removed From Muted User List_', 1, 'md')
      end

      if input:match('^[/!#]mutelist') then
        if redis:scard('muteusers:'..chat_id) == 0 then
          tdcli.sendText(chat_id, 0, 0, 1, nil, '_Not Muted User In This Group', 1, 'md')
        end
        local text = "Muted User List:\n"
        for k,v in pairs(redis:smembers('muteusers:'..chat_id)) do
          text = text.."<b>"..k.."</b> - <b>"..v.."</b>\n"
        end
        tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
      end
      -------------------------------------------------------

      --lock links
      --groups = redis:sismember('groups',chat_id)
      if input:match("^[#!/]lock link$") and is_mod(msg) and groups then
        if redis:get('lock_linkstg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Link* _Posting Is Already Locked_', 1, 'md')
        else
          redis:set('lock_linkstg:'..chat_id, true)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Link* _Posting Has Been Locked_', 1, 'md')
        end
      end
      if input:match("^[#!/]unlock link$")  and is_mod(msg) and groups then
        if not redis:get('lock_linkstg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Link* _Posting Is Already UnLocked_', 1, 'md')
        else
          redis:del('lock_linkstg:'..chat_id)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Link* _Posting Has Been UnLocked_', 1, 'md')
        end
      end
      --lock username
      groups = redis:sismember('groups',chat_id)
      if input:match("^[#!/]lock username$") and is_mod(msg) and groups then
        if redis:get('usernametg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Tag* _Posting Is Already Locked_', 1, 'md')
        else
          redis:set('usernametg:'..chat_id, true)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Tag* _Posting Has Been Locked_', 1, 'md')
        end
      end
      if input:match("^[#!/]unlock username$") and is_mod(msg) and groups then
        if not redis:get('usernametg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Tag* _Posting Is Already UnLocked_', 1, 'md')
        else
          redis:del('usernametg:'..chat_id)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Tag* _Posting Has Been UnLocked_', 1, 'md')
        end
      end
      --lock tag
      groups = redis:sismember('groups',chat_id)
      if input:match("^[#!/]lock tag$") and is_mod(msg) and groups then
        if redis:get('tagtg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*HashTag* _Posting Is Already Locked_', 1, 'md')
        else
          redis:set('tagtg:'..chat_id, true)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*HashTag* _Posting Has Been Locked_', 1, 'md')
        end
      end
      if input:match("^[#!/]unlock tag$") and is_mod(msg) and groups then
        if not redis:get('tagtg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*HashTag* _Posting Is Already UnLocked_', 1, 'md')
        else
          redis:del('tagtg:'..chat_id)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*HashTag* _Posting Has Been UnLocked_', 1, 'md')
        end
      end
      --lock forward
      groups = redis:sismember('groups',chat_id)
      if input:match("^[#!/]lock forward$") and is_mod(msg) and groups then
        if redis:get('forwardtg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Forward* _Posting Is Already Locked_', 1, 'md')
        else
          redis:set('forwardtg:'..chat_id, true)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Forward* _Posting Has Been Locked_', 1, 'md')
        end
      end
      if input:match("^[#!/]unlock forward$") and is_mod(msg) and groups then
        if not redis:get('forwardtg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Forward* _Posting Is Already UnLocked_', 1, 'md')
        else
          redis:del('forwardtg:'..chat_id)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Forward* _Posting Has Been UnLocked_', 1, 'md')
        end
      end
      --arabic/persian
      groups = redis:sismember('groups',chat_id)
      if input:match("^[#!/]lock arabic$") and is_mod(msg) and groups then
        if redis:get('arabictg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Arabic/Persian* _Posting Is Already Locked_', 1, 'md')
        else
          redis:set('arabictg:'..chat_id, true)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Arabic/Persian* _Posting Has Been Locked_', 1, 'md')
        end
      end
      if input:match("^[#!/]unlock arabic$") and is_mod(msg) and groups then
        if not redis:get('arabictg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Arabic/Persian* _Posting Is Already UnLocked_', 1, 'md')
        else
          redis:del('arabictg:'..chat_id)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Arabic/Persian* _Posting Has Been UnLocked_', 1, 'md')
        end
      end
      ---english
      groups = redis:sismember('groups',chat_id)
      if input:match("^[#!/]lock english$") and is_mod(msg) and groups then
        if redis:get('engtg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*English* _Posting Is Already Locked_', 1, 'md')
        else
          redis:set('engtg:'..chat_id, true)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*English* _Posting Has Been Locked_', 1, 'md')
        end
      end
      if input:match("^[#!/]unlock english$") and is_mod(msg) and groups then
        if not redis:get('engtg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*English* _Posting Is Already UnLocked_', 1, 'md')
        else
          redis:del('engtg:'..chat_id)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*English* _Posting Has Been UnLocked_', 1, 'md')
        end
      end
      --lock foshtg
      groups = redis:sismember('groups',chat_id)
      if input:match("^[#!/]lock fosh$") and is_mod(msg) and groups then
        if redis:get('badwordtg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*BadWord* _Posting Is Already Locked_', 1, 'md')
        else
          redis:set('badwordtg:'..chat_id, true)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*BadWord* _Posting Has Been Locked_', 1, 'md')
        end
      end
      if input:match("^[#!/]unlock fosh$") and is_mod(msg) and groups then
        if not redis:get('badwordtg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*BadWord* _Posting Is Already UnLocked_', 1, 'md')
        else
          redis:del('badwordtg:'..chat_id)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*BadWord* _Posting Has Been UnLocked_', 1, 'md')
        end
      end
      --lock edit
     -- groups = redis:sismember('groups',chat_id)
      if input:match("^[#!/]lock edit$") and is_mod(msg) and groups then
        if redis:get('edittg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Edit* _Is Already Locked_', 1, 'md')
        else
          redis:set('edittg:'..chat_id, true)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Edit* _Has Been Locked_', 1, 'md')
        end
      end
      if input:match("^[#!/]unlock edit$") and is_mod(msg) and groups then
        if not redis:get('edittg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Edit* _Is Already UnLocked_', 1, 'md')
        else
          redis:del('edittg:'..chat_id)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Edit* _Has Been UnLocked_', 1, 'md')
        end
      end		
	--lock pin
      groups = redis:sismember('groups',chat_id)
      if input:match("^[#!/]lock pin$") and is_mod(msg) and groups then
        if redis:get('pintg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Pin* _Is Already Locked_', 1, 'md')
        else
          redis:set('pintg:'..chat_id, true)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Pin* _Has Been Locked_', 1, 'md')
        end
      end
      if input:match("^[#!/]unlock pin$") and is_mod(msg) and groups then
        if not redis:get('pintg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Pin* _Is Already UnLocked_', 1, 'md')
        else
          redis:del('pintg:'..chat_id)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Pin* _Has Been UnLocked_', 1, 'md')
        end
      end		
      --- lock Caption
      if input:match("^[#!/]lock caption$") and is_mod(msg) and groups then
        if redis:get('captg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Caption* _Posting Is Already Locked_', 1, 'md')
        else
          redis:set('captg:'..chat_id, true)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Caption* _Posting Has Been Locked_', 1, 'md')
        end
      end
      if input:match("^[#!/]unlock caption$") and is_mod(msg) and groups then
        if not redis:get('captg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Caption* _Posting Is Already UnLocked_', 1, 'md')
        else
          redis:del('captg:'..chat_id)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Caption* _Posting Has Been UnLocked_', 1, 'md')
        end
      end
      --lock emoji
      groups = redis:sismember('groups',chat_id)
      if input:match("^[#!/]lock emoji") and is_mod(msg) and groups then
        if redis:get('emojitg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Emoji* _Posting Is Already Locked_', 1, 'md')
        else
          redis:set('emojitg:'..chat_id, true)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Emoji* _Posting Has Been Locked_', 1, 'md')
        end
      end
      if input:match("^[#!/]unlock emoji$") and is_mod(msg) and groups then
        if not redis:get('emojitg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Emoji* _Posting Is Already UnLocked_', 1, 'md')
        else
          redis:del('emojitg:'..chat_id)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Emoji* _Posting Has Been UnLocked_', 1, 'md')
        end
      end
      --- lock inline
      groups = redis:sismember('groups',chat_id)
      if input:match("^[#!/]lock inline") and is_mod(msg) and groups then
        if redis:get('inlinetg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Inline* _Posting Is Already Locked_', 1, 'md')
        else
          redis:set('inlinetg:'..chat_id, true)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Inline* _Posting Has Been Locked_', 1, 'md')
        end
      end
      if input:match("^[#!/]unlock inline$") and is_mod(msg) and groups then
        if not redis:get('inlinetg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Inline* _Posting Is Already UnLocked_', 1, 'md')
        else
          redis:del('inlinetg:'..chat_id)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Inline* _Posting Has Been UnLocked_', 1, 'md')
        end
      end
      -- lock reply
      groups = redis:sismember('groups',chat_id)
      if input:match("^[#!/]lock reply") and is_mod(msg) and groups then
        if redis:get('replytg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Reply* _Posting Is Already Locked_', 1, 'md')
        else
          redis:set('replytg:'..chat_id, true)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Reply* _Posting Has Been Locked_', 1, 'md')
        end
      end
      if input:match("^[#!/]unlock reply$") and is_mod(msg) and groups then
        if not redis:get('replytg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Reply* _Posting Is Already UnLocked_', 1, 'md')
        else
          redis:del('replytg:'..chat_id)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Reply* _Posting Has Been UnLocked_', 1, 'md')
        end
      end
      --lock tgservice
      groups = redis:sismember('groups',chat_id)
      if input:match("^[#!/][Ll]ock tgservice$") and is_mod(msg) and groups then
        if redis:get('tgservice:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*TGservice* _Is Already Locked_', 1, 'md')
        else
          redis:set('tgservice:'..chat_id, true)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*TGservice* _Has Been Locked_', 1, 'md')
        end
      end
      if input:match("^[#!/][Uu]nlock tgservice$") and is_mod(msg) and groups then
        if not redis:get('tgservice:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*TGservice* _Is Already Locked_', 1, 'md')
        else
          redis:del('tgservice:'..chat_id)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*TGservice* _Has Been UnLocked_', 1, 'md')
        end
      end
      --lock flood (by @Flooding)
      groups = redis:sismember('groups',chat_id)
      if input:match("^[#!/]lock flood") and is_mod(msg) and groups then
        if redis:get('floodtg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Flood* _Is Already Locked_', 1, 'md')
        else
          redis:set('floodtg:'..chat_id, true)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Flood* _Has Been Locked_', 1, 'md')
        end
      end
      if input:match("^[#!/]unlock flood$") and is_mod(msg) and groups then
        if not redis:get('floodtg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Flood* _Is Already UnLocked_', 1, 'md')
        else
          redis:del('flood:'..chat_id)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Flood* _Has Been UnLocked_', 1, 'md')
        end
      end

	groups = redis:sismember('groups',chat_id)
      if input:match("^[#!/][Ll]ock contact$") and is_mod(msg) and groups then
        if redis:get('lock_contacttg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Contact* _Posting Is Already Locked_', 1, 'md')
        else
          redis:set('lock_contacttg:'..chat_id, true)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Contact* _Posting Has Been Locked_', 1, 'md')
        end
      end
      if input:match("^[#!/][Uu]nlock contact$") and is_mod(msg) and groups then
        if not redis:get('lock_contacttg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Contact* _Posting Is Already UnLocked_', 1, 'md')
        else
          redis:del('lock_contacttg:'..chat_id)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Contact* _Posting Has Been UnLocked_', 1, 'md')
        end
      end	
	
	groups = redis:sismember('groups',chat_id)
      if input:match("^[#!/][Ll]ock sticker$") and is_mod(msg) and groups then
        if redis:get('lock_stickertg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Sticker* _Posting Is Already Locked_', 1, 'md')
        else
          redis:set('lock_stickertg:'..chat_id, true)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Sticker* _Posting Has Been Locked_', 1, 'md')
        end
      end
      if input:match("^[#!/][Uu]nlock sticker$") and is_mod(msg) and groups then
        if not redis:get('lock_stickertg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Sticker* _Posting Is Already UnLocked_', 1, 'md')
        else
          redis:del('lock_stickertg:'..chat_id)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Sticker* _Posting Has Been UnLocked_', 1, 'md')
        end
      end		
			
      --------------------------------
      ---------------------------------------------------------------------------------
      local link = 'lock_linkstg:'..chat_id
      if redis:get(link) then
        link = "`Lock`"
      else
        link = "`UnLock`"
      end

      local username = 'usernametg:'..chat_id
      if redis:get(username) then
        username = "`Lock`"
      else
        username = "`UnLock`"
      end

      local tag = 'tagtg:'..chat_id
      if redis:get(tag) then
        tag = "`Lock`"
      else
        tag = "`UnLock`"
      end

      local flood = 'flood:'..chat_id
      if redis:get(flood) then
        flood = "`Lock`"
      else
        flood = "`UnLock`"
      end

      local forward = 'forwardtg:'..chat_id
      if redis:get(forward) then
        forward = "`Lock`"
      else
        forward = "`UnLock`"
      end

      local arabic = 'arabictg:'..chat_id
      if redis:get(arabic) then
        arabic = "`Lock`"
      else
        arabic = "`UnLock`"
      end

      local eng = 'engtg:'..chat_id
      if redis:get(eng) then
        eng = "`Lock`"
      else
        eng = "`UnLock`"
      end

      local badword = 'badwordtg:'..chat_id
      if redis:get(badword) then
        badword = "`Lock`"
      else
        badword = "`UnLock`"
      end

      local edit = 'edittg:'..chat_id
      if redis:get(edit) then
        edit = "`Lock`"
      else
        edit = "`UnLock`"
      end

	local pin = 'pintg:'..chat_id
      if redis:get(pin) then
        edit = "`Lock`"
      else
        edit = "`UnLock`"
      end		
			
      local emoji = 'emojitg:'..chat_id
      if redis:get(emoji) then
        emoji = "`Lock`"
      else
        emoji = "`UnLock`"
      end

      local caption = 'captg:'..chat_id
      if redis:get(caption) then
        caption = "`Lock`"
      else
        caption = "`UnLock`"
      end

      local inline = 'inlinetg:'..chat_id
      if redis:get(inline) then
        inline = "`Lock`"
      else
        inline = "`UnLock`"
      end

      local reply = 'replytg:'..chat_id
      if redis:get(reply) then
        reply = "`Lock`"
      else
        reply = "`UnLock`"
      end
			
	local contact = 'lock_contacttg:'..chat_id
      if redis:get(contact) then
        contact = "`Lock`"
      else
        contact = "`UnLock`"
      end		
		
	local sticker = 'lock_stickertg:'..chat_id
      if redis:get(sticker) then
        sticker = "`Lock`"
      else
        sticker = "`UnLock`"
      end		
			
      ----------------------------
      --muteall
      groups = redis:sismember('groups',chat_id)
      if input:match("^[#!/][Mm]ute all$") and is_mod(msg) and groups then
        if redis:get('mute_alltg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*All* _Things Is Already Muted_', 1, 'md')
        else
          redis:set('mute_alltg:'..chat_id, true)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*All* _Things Has Been Muted_', 1, 'md')
        end
      end
      if input:match("^[#!/][Uu]nmute all$") and is_mod(msg) and groups then
        if not redis:get('mute_alltg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*All* _Things Is Already UnMuted_', 1, 'md')
        else
          redis:del('mute_alltg:'..chat_id)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*All* _Things Has Been UnMuted_', 1, 'md')
        end
      end

      --mute gift
      groups = redis:sismember('groups',chat_id)
      if input:match("^[#!/][Mm]ute gif$") and is_mod(msg) and groups then
        if redis:get('mute_gifttg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Gif* _Is Already Muted_', 1, 'md')
        else
          redis:set('mute_gifttg:'..chat_id, true)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Gif* _Has Been Muted_', 1, 'md')
        end
      end
      if input:match("^[#!/][Uu]nmute gif$") and is_mod(msg) and groups then
        if not redis:get('mute_gifttg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Gif* _Is Already UnMuted_', 1, 'md')
        else
          redis:del('mute_gifttg:'..chat_id)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Gif* _Has Been UnMuted_', 1, 'md')
        end
      end
      
      --mute photo
      groups = redis:sismember('groups',chat_id)
      if input:match("^[#!/][Mm]ute photo$") and is_mod(msg) and groups then
        if redis:get('mute_phototg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Photo* _Is Already Muted_', 1, 'md')
        else
          redis:set('mute_phototg:'..chat_id, true)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Photo* _Has Been Muted_', 1, 'md')
        end
      end
      if input:match("^[#!/][Uu]nmute photo$") and is_mod(msg) and groups then
        if not redis:get('mute_phototg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Photo* _Is Already UnMuted_', 1, 'md')
        else
          redis:del('mute_phototg:'..chat_id)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Photo* _Has Been UnMuted_', 1, 'md')
        end
      end
      --mute audio
      groups = redis:sismember('groups',chat_id)
      if input:match("^[#!/][Mm]ute audio$") and is_mod(msg) and groups then
        if redis:get('mute_audiotg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Audio* _Is Already Muted_', 1, 'md')
        else
          redis:set('mute_audiotg:'..chat_id, true)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Audio* _Has Been Muted_', 1, 'md')
        end
      end
      if input:match("^[#!/][Uu]nmute audio$") and is_mod(msg) and groups then
        if not redis:get('mute_audiotg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Audio* _Is Already UnMuted_', 1, 'md')
        else
          redis:del('mute_audiotg:'..chat_id)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Audio* _Has Been UnMuted_', 1, 'md')
        end
      end
      --mute voice
      groups = redis:sismember('groups',chat_id)
      if input:match("^[#!/][Mm]ute voice$") and is_mod(msg) and groups then
        if redis:get('mute_voicetg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Voice* _Is Already Muted_', 1, 'md')
        else
          redis:set('mute_voicetg:'..chat_id, true)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Voice* _Has Been Muted_', 1, 'md')
        end
      end
      if input:match("^[#!/][Uu]nmute voice$") and is_mod(msg) and groups then
        if not redis:get('mute_voicetg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Voice* _Is Already UnMuted_', 1, 'md')
        else
          redis:del('mute_videotg:'..chat_id)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Voice* _Has Been UnMuted_', 1, 'md')
        end
      end
      --mute video
      groups = redis:sismember('groups',chat_id)
      if input:match("^[#!/][Mm]ute video$") and is_mod(msg) and groups then
        if redis:get('mute_videotg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Video* _Is Already Muted_', 1, 'md')
        else
          redis:set('mute_videotg:'..chat_id, true)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Video* _Has Been Muted_', 1, 'md')
        end
      end
      if input:match("^[#!/][Uu]nmute video$") and is_mod(msg) and groups then
        if not redis:get('mute_videotg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Video* _Is Already UnMuted_', 1, 'md')
        else
          redis:del('mute_videotg:'..chat_id)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Video* _Has Been UnMuted_', 1, 'md')
        end
      end
      --mute document
      groups = redis:sismember('groups',chat_id)
      if input:match("^[#!/][Mm]ute document$") and is_mod(msg) and groups then
        if redis:get('mute_documenttg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Document* _Is Already Muted_', 1, 'md')
        else
          redis:set('mute_documenttg:'..chat_id, true)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Document* _Has Been Muted_', 1, 'md')
        end
      end
      if input:match("^[#!/][Uu]nmute document$") and is_mod(msg) and groups then
        if not redis:get('mute_documenttg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Document* _Is Already UnMuted_', 1, 'md')
        else
          redis:del('mute_documenttg:'..chat_id)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Document* _Has Been UnMuted_', 1, 'md')
        end
      end
      --mute  text
      groups = redis:sismember('groups',chat_id)
      if input:match("^[#!/][Mm]ute text$") and is_mod(msg) and groups then
        if redis:get('mute_texttg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Text* _Is Already Muted_', 1, 'md')
        else
          redis:set('mute_texttg:'..chat_id, true)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Text* _Has Been Muted_', 1, 'md')
        end
      end
      if input:match("^[#!/][Uu]nmute text$") and is_mod(msg) and groups then
        if not redis:get('mute_texttg:'..chat_id) then
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Text* _Is Already UnMuted_', 1, 'md')
        else
          redis:del('mute_texttg:'..chat_id)
          tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Text* _Has Been UnMuted_', 1, 'md')
        end
      end
      --settings
      local all = 'mute_alltg:'..chat_id
      if redis:get(all) then
        All = "`Mute`"
      else
        All = "`UnMute`"
      end

      local sticker = 'mute_stickertg:'..chat_id
      if redis:get(sticker) then
        sticker = "`Mute`"
      else
        sticker = "`UnMute`"
      end

      local gift = 'mute_gifttg:'..chat_id
      if redis:get(gift) then
        gift = "`Mute`"
      else
        gift = "`UnMute`"
      end

      local contact = 'mute_contacttg:'..chat_id
      if redis:get(contact) then
        contact = "`Mute`"
      else
        contact = "`UnMute`"
      end

      local photo = 'mute_phototg:'..chat_id
      if redis:get(photo) then
        photo = "`Mute`"
      else
        photo = "`UnMute`"
      end

      local audio = 'mute_audiotg:'..chat_id
      if redis:get(audio) then
        audio = "`Mute`"
      else
        audio = "`UnMute`"
      end

      local voice = 'mute_voicetg:'..chat_id
      if redis:get(voice) then
        voice = "`Mute`"
      else
        voice = "`UnMute`"
      end

      local video = 'mute_videotg:'..chat_id
      if redis:get(video) then
        video = "`Mute`"
      else
        video = "`UnMute`"
      end

      local document = 'mute_documenttg:'..chat_id
      if redis:get(document) then
        document = "`Mute`"
      else
        document = "`UnMute`"
      end

      local text1 = 'mute_texttg:'..chat_id
      if redis:get(text1) then
        text1 = "`Mute`"
      else
        text1 = "`UnMute`"
      end
      if input:match("^[#!/][Ss]ettings$") and is_mod(msg) then
        local text = "*Group Settings:*".."\n"
	.."*--------------------*".."\n"			
        .."*Link: *".."`"..link.."`".."\n"
        .."*HashTag{#}: *".."`"..tag.."`".."\n"
        .."*Tag{@}: *".."`"..username.."`".."\n"
        .."*Forward: *".."`"..forward.."`".."\n"
	.."*Sticker: *".."`"..sticker.."`".."\n"
	.."*Contact: *".."`"..contact.."`".."\n"			
	.."*Caption: *".."`"..caption..'`'..'\n'			
        .."*Arabic/Persian: *".."`"..arabic..'`'..'\n'
        .."*English: *".."`"..eng..'`'..'\n'
        .."*Reply: *".."`"..reply..'`'..'\n'
        .."*Badword: *".."`"..badword..'`'..'\n'
	.."*Emoji: *".."`"..emoji..'`'..'\n'			
        .."*Edit: *".."`"..edit..'`'..'\n'
	.."*Pin: *".."`"..pin..'`'..'\n'			
        .."*Inline: *".."`"..inline..'`'..'\n'			
	.."*Flood: *".."`"..flood.."`".."\n"			
        .."*--------------------*".."\n"
	.."*Flood Settings:*".."\n"		
	.."*Flood Max: *".."`5`".."\n"
	.."*Flood Time: *".."`3`".."\n"
	.."*Max Char: *".."`4069`".."\n"
	.."*--------------------*".."\n"
        .."*Mutes List:*".."\n"
        .."*All: *".."`"..All.."`".."\n"
	.."*Text: *".."`"..text1.."`".."\n"			
        .."*Gif: *".."`"..gift.."`".."\n"
        .."*Photo: *".."`"..photo.."`".."\n"
	.."*Video: *".."`"..video.."`".."\n"			
        .."*Audio: *".."`"..audio.."`".."\n"
        .."*Voice: *".."`"..voice.."`".."\n"
        .."*Document : *".."`"..document.."`".."\n"
	.."*--------------------*".."\n"
	.."*Language Settings:*".."\n"
	.."*Group Language: *".."`EN`".."\n"
	.."*--------------------*".."\n"			
        .."*BOT V-1"
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
      end
      if input:match("^[#!/][Ff]wd$") then
        tdcli.forwardMessages(chat_id, chat_id,{[0] = reply_id}, 0)
      end

      if input:match("^[#!/][Uu]sername") and is_sudo(msg) then
        tdcli.changeUsername(string.sub(input, 11))
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '<b>Username Changed To </b>@'..string.sub(input, 11), 1, 'html')
      end

      if input:match("^[#!/][Ee]cho") then
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, string.sub(input, 7), 1, 'html')
      end

      if input:match("^[#!/][Ss]etname") and is_owner(msg) then
        tdcli.changeChatTitle(chat_id, string.sub(input, 10), 1)
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '<b>SuperGroup Name Changed To </b><code>'..string.sub(input, 10)..'</code>', 1, 'html')
      end
	  
      if input:match("^[#!/][Cc]hangename") and is_sudo(msg) then
        tdcli.changeName(string.sub(input, 13), nil, 1)
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '<b>Bot Name Changed To </b><code>'..string.sub(input, 13)..'</code>', 1, 'html')
      end
	  
      if input:match("^[#!/][Cc]hangeuser") and is_sudo(msg) then
        tdcli.changeUsername(string.sub(input, 13), nil, 1)
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '<b>Bot UserName Changed To </b><code>'..string.sub(input, 13)..'</code>', 1, 'html')
      end
	  
      if input:match("^[#!/][Dd]eluser") and is_sudo(msg) then
        tdcli.changeUsername('')
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '#Done\nUsername Has Been Deleted', 1, 'html')
      end
	  
      if input:match("^[#!/][Ee]dit") and is_owner(msg) then
        tdcli.editMessageText(chat_id, reply_id, nil, string.sub(input, 7), 'html')
      end

      if input:match("^[#!/]delpro") and is_sudo(msg) then
        tdcli.DeleteProfilePhoto(chat_id, {[0] = msg.id_})
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '<b>#done profile has been deleted</b>', 1, 'html')
      end

      if input:match("^[#!/][Ii]nvite") and is_sudo(msg) then
        tdcli.addChatMember(chat_id, string.sub(input, 9), 20)
      end
	  
      if input:match("^[#!/][Cc]reatesuper") and is_sudo(msg) then
        tdcli.createNewChannelChat(string.sub(input, 14), 1, 'My Supergroup, my rules')
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '<b>SuperGroup </b>'..string.sub(input, 14)..' <b>Created</b>', 1, 'html')
      end

      if input:match("^[#!/]del") and is_mod(msg) and msg.reply_to_message_id_ ~= 0 then
        tdcli.deleteMessages(msg.chat_id_, {[0] = msg.reply_to_message_id_})
      end

      if input:match('^[#!/]tosuper') then
        local gpid = msg.chat_id_
        tdcli.migrateGroupChatToChannelChat(gpid)
      end

      if input:match("^[#!/]view") then
        tdcli.viewMessages(chat_id, {[0] = msg.id_})
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '<b>Messages Viewed</b>', 1, 'html')
      end
    end

    local input = msg.content_.text_
    if redis:get('mute_alltg:'..chat_id) and msg and not is_owner(msg) then
      tdcli.deleteMessages(chat_id, {[0] = msg.id_})
    end

    if redis:get('mute_stickertg:'..chat_id) and msg.content_.sticker_ and not is_mod(msg) then
      tdcli.deleteMessages(chat_id, {[0] = msg.id_})
    end

    if redis:get('mute_giftg:'..chat_id) and msg.content_.animation_ and not is_mod(msg) then
      tdcli.deleteMessages(chat_id, {[0] = msg.id_})
    end

    if redis:get('mute_contacttg:'..chat_id) and msg.content_.contact_ and not is_mod(msg) then
      tdcli.deleteMessages(chat_id, {[0] = msg.id_})
    end

    if redis:get('mute_phototg:'..chat_id) and msg.content_.photo_ and not is_mod(msg) then
      tdcli.deleteMessages(chat_id, {[0] = msg.id_})
    end

    if redis:get('mute_audiotg:'..chat_id) and msg.content_.audio_ and not is_mod(msg) then
      tdcli.deleteMessages(chat_id, {[0] = msg.id_})
    end

    if redis:get('mute_voicetg:'..chat_id) and msg.content_.voice_  and not is_mod(msg) then
      tdcli.deleteMessages(chat_id, {[0] = msg.id_})
    end

    if redis:get('mute_videotg:'..chat_id) and msg.content_.video_ and not is_mod(msg) then
      tdcli.deleteMessages(chat_id, {[0] = msg.id_})
    end

    if redis:get('mute_documenttg:'..chat_id) and msg.content_.document_ and not is_mod(msg) then
      tdcli.deleteMessages(chat_id, {[0] = msg.id_})
    end

    if redis:get('mute_texttg:'..chat_id) and msg.content_.text_ and not is_mod(msg) then
      tdcli.deleteMessages(chat_id, {[0] = msg.id_})
    end
    if redis:get('forwardtg:'..chat_id) and msg.forward_info_ and not is_mod(msg) then
      tdcli.deleteMessages(chat_id, {[0] = msg.id_})
    end

    if redis:get('lock_linkstg:'..chat_id) and input:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]/") and not is_mod(msg) then
      tdcli.deleteMessages(chat_id, {[0] = msg.id_})
    end

    if redis:get('tagtg:'..chat_id) and input:match("#") and not is_mod(msg) then
      tdcli.deleteMessages(chat_id, {[0] = msg.id_})
    end

    if redis:get('usernametg:'..chat_id) and input:match("@") and not is_mod(msg) then
      tdcli.deleteMessages(chat_id, {[0] = msg.id_})
    end

    if redis:get('arabictg:'..chat_id) and input:match("[\216-\219][\128-\191]") and not is_mod(msg) then
      tdcli.deleteMessages(chat_id, {[0] = msg.id_})
    end

    local is_english_msg = input:match("[a-z]") or input:match("[A-Z]")
    if redis:get('engtg:'..chat_id) and is_english_msg and not is_mod(msg) then
      tdcli.deleteMessages(chat_id, {[0] = msg.id_})
    end

    local is_fosh_msg = input:match("کیر") or input:match("کس") or input:match("کون") or input:match("85") or input:match("جنده") or input:match("ننه") or input:match("ننت") or input:match("مادر") or input:match("قهبه") or input:match("گایی") or input:match("سکس") or input:match("kir") or input:match("kos") or input:match("kon") or input:match("nne") or input:match("nnt")
    if redis:get('badwordtg:'..chat_id) and is_fosh_msg and not is_mod(msg) then
      tdcli.deleteMessages(chat_id, {[0] = msg.id_})
    end

    local is_emoji_msg = input:match("😀") or input:match("😬") or input:match("😁") or input:match("😂") or  input:match("😃") or input:match("😄") or input:match("😅") or input:match("☺️") or input:match("🙃") or input:match("🙂") or input:match("😊") or input:match("😉") or input:match("😇") or input:match("😆") or input:match("😋") or input:match("😌") or input:match("😍") or input:match("😘") or input:match("😗") or input:match("😙") or input:match("😚") or input:match("🤗") or input:match("😎") or input:match("🤓") or input:match("🤑") or input:match("😛") or input:match("😏") or input:match("😶") or input:match("😐") or input:match("😑") or input:match("😒") or input:match("🙄") or input:match("🤔") or input:match("😕") or input:match("😔") or input:match("😡") or input:match("😠") or input:match("😟") or input:match("😞") or input:match("😳") or input:match("🙁") or input:match("☹️") or input:match("😣") or input:match("😖") or input:match("😫") or input:match("😩") or input:match("😤") or input:match("😲") or input:match("😵") or input:match("😭") or input:match("😓") or input:match("😪") or input:match("😥") or input:match("😢") or input:match("🤐") or input:match("😷") or input:match("🤒") or input:match("🤕") or input:match("😴") or input:match("💋") or input:match("❤️")
    if redis:get('emojitg:'..chat_id) and is_emoji_msg and not is_mod(msg)  then
      tdcli.deleteMessages(chat_id, {[0] = msg.id_})
    end

    if redis:get('captg:'..chat_id) and  msg.content_.caption_ and not is_mod(msg) then
      tdcli.deleteMessages(chat_id, {[0] = msg.id_})
    end

    if redis:get('locatg:'..chat_id) and  msg.content_.location_ and not is_mod(msg) then
      tdcli.deleteMessages(chat_id, {[0] = msg.id_})
    end

    if redis:get('inlinetg:'..chat_id) and  msg.via_bot_user_id_ ~= 0 and not is_mod(msg) then
      tdcli.deleteMessages(chat_id, {[0] = msg.id_})
    end

    if redis:get('replytg:'..chat_id) and  msg.reply_to_message_id_ and not is_mod(msg) ~= 0 then
      tdcli.deleteMessages(chat_id, {[0] = msg.id_})
    end

    if redis:get('tbt:'..chat_id) and is_normal(msg) then
      tdcli.deleteMessages(chat_id, {[0] = msg.id_})
    end
    -- AntiFlood --
    local floodMax = 5
    local floodTime = 2
    local hashflood = 'floodtg:'..msg.chat_id_
    if redis:get(hashflood) and not is_mod(msg) then
      local hash = 'flood:'..msg.sender_user_id_..':'..msg.chat_id_..':msg-num'
      local msgs = tonumber(redis:get(hash) or 0)
      if msgs > (floodMax - 1) then
        tdcli.changeChatMemberStatus(msg.chat_id_, msg.sender_user_id_, "Kicked")
        tdcli.sendText(msg.chat_id_, msg.id_, 1, '_User_ *['..msg.sender_user_id_..']* _Flooding Is Not Allowed Here!_\n`Flooder Has Been Kicked', 1, 'md')
        redis:setex(hash, floodTime, msgs+1)
      end
    end
    -- AntiFlood --
		elseif data.ID == "UpdateMessageEdited" then
if redis:get('edittg:'..data.chat_id_) then
  tdcli.deleteMessages(data.chat_id_, {[0] = tonumber(data.message_id_)})
end 
  elseif (data.ID == "UpdateOption" and data.name_ == "my_id") then
	
    
    tdcli_function ({
      ID="GetChats",
      offset_order_="9223372036854775807",
      offset_chat_id_=0,
      limit_=20
    }, dl_cb, nil)
  end
end
