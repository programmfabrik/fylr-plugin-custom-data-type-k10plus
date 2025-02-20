const fs = require('fs')
const https = require('https')
const fetch = (...args) => import('node-fetch').then(({
  default: fetch
}) => fetch(...args));

let databaseLanguages = [];
let frontendLanguages = [];

let defaultLanguage = 'de';

let info = {}

let access_token = '';

if (process.argv.length >= 3) {
    info = JSON.parse(process.argv[2]);
}

function hasChanges(objectOne, objectTwo) {
  var len;
  const ref = ["conceptName", "conceptURI", "conceptSource", "_standard", "_fulltext", "facetTerm", "frontendLanguage"];
  for (let i = 0, len = ref.length; i < len; i++) {
    let key = ref[i];
    if (!k10plusUtilities.isEqual(objectOne[key], objectTwo[key])) {
      return true;
    }
  }
  return false;
}

function getConfigFromAPI() {
        return new Promise((resolve, reject) => {
                var url = 'http://fylr.localhost:8081/api/v1/config?access_token=' + access_token
                fetch(url, {
                                headers: {
                                        'Accept': 'application/json'
                                },
                        })
                        .then(response => {
                                if (response.ok) {
                                        resolve(response.json());
                                } else {
                                        console.error("Getty-Updater: Fehler bei der Anfrage an /config ");
                                }
                        })
                        .catch(error => {
                                console.error(error);
                                console.error("Getty-Updater: Fehler bei der Anfrage an /config");
                        });
        });
}

main = (payload) => {
  switch (payload.action) {
    case "start_update":
      outputData({
        "state": {
          "personal": 2
        },
        "log": ["started logging"]
      })
      break
    case "update":
      ////////////////////////////////////////////////////////////////////////////
      // run k10plus-api-call for every given uri
      ////////////////////////////////////////////////////////////////////////////

      // collect URIs
      let URIList = [];
      for (var i = 0; i < payload.objects.length; i++) {
        URIList.push(payload.objects[i].data.conceptURI);
      }
      // unique urilist
      URIList = [...new Set(URIList)]

      let requestUrls = [];
      let requests = [];

      URIList.forEach((uri) => {
        const conceptSource = (uri.match(/document\/(.*):ppn/) || [])[1] || null;
        const PPN = (uri.match(/:ppn:(.*)/ || [])[1]) || null;
        if (conceptSource) {
          let dataRequestUrl = 'https://ws.gbv.de/suggest/csl2/?query=pica.ppn=' + PPN + '&citationstyle=ieee&language=de&count=1&database=' + conceptSource;
          let dataRequest = fetch(dataRequestUrl);
          requests.push({
            url: dataRequestUrl,
            uri: uri,
            request: dataRequest
          });
          requestUrls.push(dataRequest);
        }
      });

      Promise.all(requestUrls).then(function(responses) {
        let results = [];
        // Get a JSON object from each of the responses
        responses.forEach((response, index) => {
          let url = requests[index].url;
          let uri = requests[index].uri;
          let result = {
            url: url,
            uri: uri,
            data: null,
            error: null
          };
          if (response.ok) {
            result.data = response.json();
          } else {
            result.error = "Error fetching data from " + url + ": " + response.status + " " + response.statusText;
          }
          results.push(result);
        });
        return Promise.all(results.map(result => result.data));
      }).then(function(data) {
        let results = [];
        data.forEach((data, index) => {
          let url = requests[index].url;
          let uri = requests[index].uri;
          let result = {
            url: url,
            uri: uri,
            data: data,
            error: null
          };
          if (data instanceof Error) {
            result.error = "Error parsing data from " + url + ": " + data.message;
          }
          results.push(result);
        });

        // build cdata from all api-request-results
        let cdataList = [];
        payload.objects.forEach((result, index) => {
          let originalCdata = payload.objects[index].data;

          let newCdata = {};
          let originalURI = originalCdata.conceptURI;

          const matchingRecordData = results.find(record => record.uri === originalURI);

          if (matchingRecordData) {
            // rematch uri, because maybe uri changed / rewrites ..
            let uri = matchingRecordData.uri;

            ///////////////////////////////////////////////////////
            // conceptName, conceptURI, conceptSource, _standard, _fulltext, facet, frontendLanguage
            resultJSON = matchingRecordData.data;
            if (resultJSON) {
              // get desired language for preflabel. This is frontendlanguage from original data...
              let desiredLanguage = originalCdata.frontendLanguage;
              // save conceptName
              newCdata.conceptName = resultJSON[1][0];
              // save conceptURI
              newCdata.conceptURI = resultJSON[3][0];
              // save conceptSource
              newCdata.conceptSource = (originalCdata.conceptURI.match(/document\/(.*):ppn/) || [])[1] || null
              // save _fulltext
              newCdata._fulltext = k10plusUtilities.getFullTextFromString(newCdata.conceptURI, newCdata.conceptName, databaseLanguages);
              // save _standard
              newCdata._standard = k10plusUtilities.getStandardFromString(newCdata.conceptName, databaseLanguages);
              // save facet
              newCdata.facetTerm = k10plusUtilities.getFacetTerm(newCdata.conceptURI, newCdata.conceptName, databaseLanguages);

              // save frontend language (same as given)
              newCdata.frontendLanguage = originalCdata.frontendLanguage;

              if (!originalCdata?.frontendLanguage?.length == 2) {
                  originalCdata.frontendLanguage = defaultLanguage;
              }
              // save frontend language (same as given or default)
              newCdata.frontendLanguage = originalCdata.frontendLanguage;

              if (hasChanges(payload.objects[index].data, newCdata)) {
                payload.objects[index].data = newCdata;
              } else {}
            }
          } else {
            console.error('No matching record found');
          }
        });
        outputData({
          "payload": payload.objects,
          "log": [payload.objects.length + " objects in payload"]
        });
      });
      // send data back for update
      break;
    case "end_update":
      outputData({
        "state": {
          "theend": 2,
          "log": ["done logging"]
        }
      });
      break;
    default:
      outputErr("Unsupported action " + payload.action);
  }
}

outputData = (data) => {
  out = {
    "status_code": 200,
    "body": data
  }
  process.stdout.write(JSON.stringify(out))
  process.exit(0);
}

outputErr = (err2) => {
  let err = {
    "status_code": 400,
    "body": {
      "error": err2.toString()
    }
  }
  console.error(JSON.stringify(err))
  process.stdout.write(JSON.stringify(err))
  process.exit(0);
}

(() => {

  let data = ""

  process.stdin.setEncoding('utf8');

  ////////////////////////////////////////////////////////////////////////////
  // check if hour-restriction is set
  ////////////////////////////////////////////////////////////////////////////

  if(info?.config?.plugin?.['custom-data-type-gvk']?.config?.update_k10plus?.restrict_time === true) {
    let plugin_config = info.config.plugin['custom-data-type-gvk'].config.update_k10plus;
    // check if hours are configured
    if(plugin_config?.from_time !== false && plugin_config?.to_time !== false) {
        const now = new Date();            
        const hour = now.getHours();
        // check if hours do not match
        if(hour < plugin_config.from_time && hour >= plugin_config.to_time) {
            // exit if hours do not match
            outputData({
                "state": {
                    "theend": 2,
                    "log": ["hours do not match, cancel update"]
                }
            });
        }
    }
  }

  access_token = info && info.plugin_user_access_token;

  if(access_token) {
    
      ////////////////////////////////////////////////////////////////////////////
      // get config and read the languages
      ////////////////////////////////////////////////////////////////////////////

      getConfigFromAPI().then(config => {
          databaseLanguages = config.system.config.languages.database;
          databaseLanguages = databaseLanguages.map((value, key, array) => {
            return value.value;
          });

          frontendLanguages = config.system.config.languages.frontend;


          ////////////////////////////////////////////////////////////////////////////
          // availabilityCheck for k10plus-api
          ////////////////////////////////////////////////////////////////////////////
          let testURL = 'https://ws.gbv.de/suggest/csl2/?query=pica.tit=Nacht&citationstyle=ieee&language=de&count=3';
          console.error("Asking for testurl:" + testURL);
          https.get(testURL, res => {
            let testData = [];
            res.on('data', chunk => {
              testData.push(chunk);
            });
            res.on('end', () => {
              testData = Buffer.concat(testData).toString();
              const testJSON = JSON.parse(testData);
              if (testJSON && testData.includes('Nacht')) {
                ////////////////////////////////////////////////////////////////////////////
                // test successfull --> continue with custom-data-type-update
                ////////////////////////////////////////////////////////////////////////////
                process.stdin.on('readable', () => {
                  let chunk;
                  while ((chunk = process.stdin.read()) !== null) {
                    data = data + chunk
                  }
                });
                process.stdin.on('end', () => {
                  ///////////////////////////////////////
                  // continue with update-routine
                  ///////////////////////////////////////
                  try {
                    let payload = JSON.parse(data)
                    main(payload)
                  } catch (error) {
                    console.error("caught error", error)
                    outputErr(error)
                  }
                });
              } else {
                console.error('Error while interpreting data from k10plus-API.');
              }
            });
          }).on('error', err => {
            console.error('Error while receiving data from k10plus-API: ', err.message);
          });
      }).catch(error => {
        console.error('Es gab einen Fehler beim Laden der Konfiguration:', error);
      });
    }
    else {
        console.error("kein Accesstoken gefunden");
    }

})();
