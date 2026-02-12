// ignore_for_file: constant_identifier_names

const MAIN_URL =
    "project1.thankfulmeadow-95cc6361.eastasia.azurecontainerapps.io";

const String BASE_URL = "https://$MAIN_URL";
const String WS_URL = "ws://$MAIN_URL/ws";
const String LOGIN_URL = "$BASE_URL/auth/login";
const String SIGNUP_URL = "$BASE_URL/auth/signup";
const String USER_CONNECTION_SENT_REQUESTS_URL =
    "$BASE_URL/user-connection/sent_requests";
const String USER_CONNECTION_RECEIVED_REQUESTS_URL =
    "$BASE_URL/user-connection/recieved_requests";
const String USER_CONNECTION_ACCEPT_URL =
    "$BASE_URL/user-connection/accept_request";
const String USER_CONNECTION_SEND_REQUEST_URL =
    "$BASE_URL/user-connection/send_request";
const String USER_CONNECTION_CONNECTED_TO_URL =
    "$BASE_URL/user-connection/connected_to";
const String USER_CONNECTION_CONNECTED_FROM_URL =
    "$BASE_URL/user-connection/connected_from";
