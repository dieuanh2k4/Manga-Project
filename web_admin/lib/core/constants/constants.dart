// const String newAPIBaseURL = 'http://192.168.0.195:5001/api/';
// const String newAPIBaseURL = 'http://10.76.200.178:5001/api/';
const String newAPIBaseURL = String.fromEnvironment(
  'API_BASE_URL',
//   defaultValue: 'http://localhost:5219/api/',
  // defaultValue: 'http://192.168.0.195:5001/api/',
  // defaultValue: 'http://10.76.200.178:5001/api/',
  defaultValue: 'http://192.168.0.200:5001/api/',
  // defaultValue: 'http://10.76.200.178:5001/api/',
  // api khi chạy ngrok
  // defaultValue: 'https://c0f0-118-71-135-136.ngrok-free.app/api/',
);
