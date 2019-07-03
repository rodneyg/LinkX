const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.grantSignupReward = functions.database.ref('/users/{uid}/last_signin_at')
    .onCreate((snap, context) => {
        var uid = context.auth.uid;
        admin.database().ref(`users/${uid}/referred_by`)
            .once('value').then(function(data) {
                var referred_by_somebody = data.val();
                console.log("Referred by is : " + data.val());

                if (referred_by_somebody != null) {
                    // A point entry.
                    var pointData = {
                        notes: "Referral",
                        activity: "Refer a Friend",
                        value: 15.0,
                        created_at: Date.now()
                    };

                    // Get a key for a new Point.
                    var newPointKey = admin.database().ref().child(`/points/` + referred_by_somebody + `/`).push().key

                    // Write the new point's data simultaneously in the points list.
                    admin.database().ref(`/points/` + referred_by_somebody + `/` + newPointKey).set(pointData);
                }
            });
    });
