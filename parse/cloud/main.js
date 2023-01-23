// main.js

Parse.Cloud.define("testCloudCode", async(request) => {
  console.log('From client: ' + JSON.stringify(request)); 
  return request.params.argument1;
});

Parse.Cloud.define("testCloudCodeError", async(request) => {
  console.log('From client: ' + JSON.stringify(request)); 
  throw new Parse.Error(3000, "cloud has an error on purpose.");
});
