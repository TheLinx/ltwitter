local http = require("socket.http")
local json = require("json")
local ltn12 = require("ltn12")
local oo = require("loop.base")
local mime = require("mime")
local url = require("socket.url")

local error,pairs = error,pairs
local tableConcat = table.concat

--- LuaTwitter
-- TODO: OAuth
-- @author Linus Sjögren <thelinx@unreliablepollution.net>
-- @version 0.9.0
-- @license CC0
module("twitter", oo.class, package.seeall)

-- local oauth

resources = {
-- Timeline resources
	publicTimeline = {"get", "statuses/public_timeline"},
	homeTimeline = {"get", "statuses/home_timeline"},
	friendsTimeline = {"get", "statuses/friends_timeline"},
	userTimeline = {"get", "statuses/user_timeline"},
	mentions = {"get", "statuses/mentions"},
	retweetedByMe = {"get", "statuses/retweeted_by_me"},
	retweetedToMe = {"get", "statuses/retweeted_to_me"},
-- Tweets resources
	retweetsOfMe = {"get", "statuses/retweets_of_me"},
	showStatus = {"get", "statuses/show"},
	updateStatus = {"post", "statuses/update"},
	destroyStatus = {"post", "statuses/destroy"},
	retweetStatus = {"post", "statuses/retweet/:id"},
	retweets = {"get", "statuses/retweets"},
	retweetedBy = {"get", "statuses/:id/retweeted_by"},
	retweetedByIds = {"get", "statuses/:id/retweeted_by/ids"},
-- User resources
	showUser = {"get", "users/show"},
	lookupUsers = {"get", "users/lookup"},
	searchUsers = {"get", "users/search"},
	suggestedUserGroups = {"get", "users/suggestions"},
	suggestedUsers = {"get", "users/suggestions/:slug"},
	profileImage = {"get", "users/profile_image/:screen_name"},
	friends = {"get", "statuses/friends"},
	followers  = {"get", "statuses/followers"},
-- Trends resources
	trends = {"get", "trends"},
	currentTrends = {"get", "trends/current"},
	dailyTrends = {"get", "trends/daily"},
	weeklyTrends = {"get", "trends/weekly"},
-- List resources
	newList = {"post", ":user/lists"},
	updateList = {"post", ":user/lists/:id"},
	userLists = {"get", ":user/lists"},
	showList = {"get", ":user/lists/:id"},
	deleteList = {"delete", ":user/lists/:id"},
	listTimeline = {"get", ":user/lists/:id/statuses"},
	listMemberships = {"get", ":user/lists/memberships"},
	listSubscriptions = {"get", ":user/lists/subscriptions"},
-- List Members resources
	getListMembers = {"get", ":user/:list_id/members"},
	addListMember = {"post", ":user/:list_id/members"},
	delListMember = {"delete", ":user/:list_id/members"},
	chkListMember = {"get", ":user/:list_id/members/:id"},
-- List Subscribers resources
	getListSubscribers = {"get", ":user/:list_id/subscribers"},
	addListSubscriber = {"post", ":user/:list_id/subscribers"},
	delListSubscriber = {"delete", ":user/:list_id/subscribers"},
	chkListSubscriber = {"get", ":user/:list_id/subscribers/:id"},
-- Direct Messages resources
	listMessages = {"get", "direct_messages"},
	sentMessages = {"get", "direct_messages/sent"},
	sendMessage = {"post", "direct_messages/new"},
	removeMessage = {"post", "direct_messages/destroy"},
-- Friendship resources
	follow = {"post", "friendships/create/:id"},
	unfollow = {"post", "friendships/destroy/:id"},
	isFollowing = {"get", "friendships/exists"},
	showRelation = {"get", "friendships/show"},
	inFriendships = {"get", "friendships/incoming"},
	outFriendships = {"get", "friendships/outgoing"},
-- Friends and Followers resources
	following = {"get", "friends/ids"},
	followers = {"get", "followers/ids"},
-- Account resources
	rateLimitStatus = {"get", "account/rate_limit_status"},
	updateDeliveryDevice = {"post", "account/update_delivery_device"},
	updateProfileColors = {"post", "account/update_profile_colors"},
	updateProfileImage = {"post", "account/update_profile_image"},
	-- holy shit take a look at that --> / <-- perfect line!!!
	updateProfileBackground = {"post", "account/update_profile_background"},
	updateProfile = {"post", "account/update_profile"},
-- Favorites resources
	favorites = {"get", "favorites"},
	addFavorite = {"post", "favorites/:id/create"},
	delFavorite = {"post", "favorites/destroy"},
-- Notifications resources
	enableNotifications = {"post", "notifications/follow"},
	disableNotifications = {"post", "notifications/unfollow"},
-- Block resources
	addBlock = {"post", "blocks/create"},
	delBlock = {"post", "blocks/destroy"},
	chkBlock = {"get", "blocks/exists"},
	blocking = {"get", "blocks/blocking"},
	blockingIds = {"get", "blocks/blocking/ids"},
-- Spam Reporting resources
	reportSpam = {"post", "report_spam"},
-- Saved Searches resources
	savedSearches = {"get", "saved_searches"},
	doSavedSearch = {"get", "saved_searches/show"},
	addSavedSearch = {"post", "saved_searches/create"},
	delSavedSearch = {"post", "saved_searches/destroy"},
-- Local Trends resources
	availableLocations = {"get", "trends/available"},
	locationTrends = {"get", "trends/locations/:woeid"},
-- Geo resources
	reverseGeocode = {"get", "geo/reverse_geocode"},
	placeInfo = {"get", "geo/id/:place_id"}
}

function __tostring()
	return "Twitter Client"
end

local function tabletopost(t)
	local out = {}
	for k,v in pairs(t) do
		out[#out+1] = ("%s=%s"):format(url.escape(k), url.escape(tostring(v)))
		out[#out+1] = "&"
	end
	out[#out] = nil
	return tableConcat(out)
end

local function tabletoget(...)
	local s = tabletopost(...)
	if #s > 0 then
		return ("?%s"):format(s)
	else
		return ""
	end
end

local function request(page, method, data)
	local url, source
	if method:lower() == "get" then
		url = ("http://api.twitter.com/1/%s.json%s"):format(page, tabletoget(data or {}))
	else
		url = ("http://api.twitter.com/1/%s.json"):format(page)
		source = ltn12.sink.table(data or {})
	end
	local out = {}
	local ret, code, headers = http.request{
		url = url,
		method = method:upper(),
		source = source,
		sink = ltn12.sink.table(out)
	}
	out = tableConcat(out)
	if out:sub(1,2) == "<!" then
		error("internal error! please report this bug at http://github.com/TheLinx/LuaTwitter/")
	end
	out = json.decode(out)
	return out
end

for name,info in pairs(resources) do
	_M[name] = function(self, arg)
		local url = info[2]:gsub(":([%w_-]+)", arg)
		return request(url, info[1], arg)
	end
end