const axios = require("axios");

console.log("STONKS in JS!");

let url = "https://api.pushshift.io/reddit/search/comment/?q=aal&after=1d&fields=body,subreddit,score&metadata=true&score=%3E10&size=10"

axios.get(url).then(response => {
    console.log(response.data);
});