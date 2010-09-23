local json = require("json")
local oauth = require("OAuth")

local assert,error,pairs,setmetatable,tostring = assert,error,pairs,setmetatable,tostring
local tableConcat = table.concat

--- ltwitter
-- @author Linus Sjögren <thelinx@unreliablepollution.net>
-- @version 1.0.0
-- @license CC0
module("twitter")

resources = {
-- Timeline resources
	publicTimeline = {"GET", "statuses/public_timeline"},
	homeTimeline = {"GET", "statuses/home_timeline"},
	friendsTimeline = {"GET", "statuses/friends_timeline"},
	userTimeline = {"GET", "statuses/user_timeline"},
	mentions = {"GET", "statuses/mentions"},
	retweetedByMe = {"GET", "statuses/retweeted_by_me"},
	retweetedToMe = {"GET", "statuses/retweeted_to_me"},
-- Tweets resources
	retweetsOfMe = {"GET", "statuses/retweets_of_me"},
	showStatus = {"GET", "statuses/show"},
	updateStatus = {"POST", "statuses/update"},
	destroyStatus = {"POST", "statuses/destroy"},
	retweetStatus = {"POST", "statuses/retweet/:id"},
	retweets = {"GET", "statuses/retweets"},
	retweetedBy = {"GET", "statuses/:id/retweeted_by"},
	retweetedByIds = {"GET", "statuses/:id/retweeted_by/ids"},
-- User resources
	showUser = {"GET", "users/show"},
	lookupUsers = {"GET", "users/lookup"},
	searchUsers = {"GET", "users/search"},
	suggestedUserGroups = {"GET", "users/suggestions"},
	suggestedUsers = {"GET", "users/suggestions/:slug"},
	profileImage = {"GET", "users/profile_image/:screen_name"},
	friends = {"GET", "statuses/friends"},
	followers  = {"GET", "statuses/followers"},
-- Trends resources
	trends = {"GET", "trends"},
	currentTrends = {"GET", "trends/current"},
	dailyTrends = {"GET", "trends/daily"},
	weeklyTrends = {"GET", "trends/weekly"},
-- List resources
	newList = {"POST", ":user/lists"},
	updateList = {"POST", ":user/lists/:id"},
	userLists = {"GET", ":user/lists"},
	showList = {"GET", ":user/lists/:id"},
	deleteList = {"DELETE", ":user/lists/:id"},
	listTimeline = {"GET", ":user/lists/:id/statuses"},
	listMemberships = {"GET", ":user/lists/memberships"},
	listSubscriptions = {"GET", ":user/lists/subscriptions"},
-- List Members resources
	getListMembers = {"GET", ":user/:list_id/members"},
	addListMember = {"POST", ":user/:list_id/members"},
	delListMember = {"DELETE", ":user/:list_id/members"},
	chkListMember = {"GET", ":user/:list_id/members/:id"},
-- List Subscribers resources
	getListSubscribers = {"GET", ":user/:list_id/subscribers"},
	addListSubscriber = {"POST", ":user/:list_id/subscribers"},
	delListSubscriber = {"DELETE", ":user/:list_id/subscribers"},
	chkListSubscriber = {"GET", ":user/:list_id/subscribers/:id"},
-- Direct Messages resources
	listMessages = {"GET", "direct_messages"},
	sentMessages = {"GET", "direct_messages/sent"},
	sendMessage = {"POST", "direct_messages/new"},
	removeMessage = {"POST", "direct_messages/destroy"},
-- Friendship resources
	follow = {"POST", "friendships/create/:id"},
	unfollow = {"POST", "friendships/destroy/:id"},
	isFollowing = {"GET", "friendships/exists"},
	showRelation = {"GET", "friendships/show"},
	inFriendships = {"GET", "friendships/incoming"},
	outFriendships = {"GET", "friendships/outgoing"},
-- Friends and Followers resources
	following = {"GET", "friends/ids"},
	followers = {"GET", "followers/ids"},
-- Account resources
	rateLimitStatus = {"GET", "account/rate_limit_status"},
	updateDeliveryDevice = {"POST", "account/update_delivery_device"},
	updateProfileColors = {"POST", "account/update_profile_colors"},
	updateProfileImage = {"POST", "account/update_profile_image"},
	-- holy shit take a look at that --> / <-- perfect line!!!
	updateProfileBackground = {"POST", "account/update_profile_background"},
	updateProfile = {"POST", "account/update_profile"},
-- Favorites resources
	favorites = {"GET", "favorites"},
	addFavorite = {"POST", "favorites/:id/create"},
	delFavorite = {"POST", "favorites/destroy"},
-- Notifications resources
	enableNotifications = {"POST", "notifications/follow"},
	disableNotifications = {"POST", "notifications/unfollow"},
-- Block resources
	addBlock = {"POST", "blocks/create"},
	delBlock = {"POST", "blocks/destroy"},
	chkBlock = {"GET", "blocks/exists"},
	blocking = {"GET", "blocks/blocking"},
	blockingIds = {"GET", "blocks/blocking/ids"},
-- Spam Reporting resources
	reportSpam = {"POST", "report_spam"},
-- Saved Searches resources
	savedSearches = {"GET", "saved_searches"},
	doSavedSearch = {"GET", "saved_searches/show"},
	addSavedSearch = {"POST", "saved_searches/create"},
	delSavedSearch = {"POST", "saved_searches/destroy"},
-- Local Trends resources
	availableLocations = {"GET", "trends/available"},
	locationTrends = {"GET", "trends/locations/:woeid"},
-- Geo resources
	reverseGeocode = {"GET", "geo/reverse_geocode"},
	placeInfo = {"GET", "geo/id/:place_id"}
}

local cl_mt = {
  __index = function(tbl, method)
    if not resources[method] then return nil end
    local resource = resources[method]
    local url = "https://api.twitter.com/1/"..resource[2]..".json"
    return function(self, args)
      args = args or {}
      local url = url:gsub(":([%w_-]+)", function (s)
        if args[s] then
          local ret = args[s]
          args[s] = nil
          return ret
        else
          return s
        end
      end)
      for k,v in pairs(args) do
        args[k] = tostring(v)
      end
      local _, _, _, body = self.oauthclient:PerformRequest(resource[1], url, args)
      return json.decode(body)
    end
  end
}

local function startLogin(self)
  return self.oauthclient:BuildAuthorizationUrl()
end
local function confirmLogin(self, pin)
  return self.oauthclient:GetAccessToken({oauth_verifier = pin})
end

function client(consumerKey, consumerSecret, tokenKey, tokenSecret, verifier)
  local o = setmetatable({}, cl_mt)
  assert(consumerKey and consumerSecret, "you need to specify a consumer key and a consumer secret!")
  o.oauthclient = oauth.new(consumerKey, consumerSecret, {
    RequestToken = "https://api.twitter.com/oauth/request_token";
    AccessToken = "https://api.twitter.com/oauth/access_token";
    AuthorizeUser = "https://api.twitter.com/oauth/authorize";
  }, {
    OAuthToken = tokenKey;
    OAuthTokenSecret = tokenSecret;
    OAuthVerifier = verifier;
    UseAuthHeaders = true;
    SignatureMethod = "HMAC-SHA1";
  })
  if not (tokenKey and tokenSecret) then
    o.oauthclient:RequestToken()
  end
  o.startLogin = startLogin
  o.confirmLogin = confirmLogin
  return o
end