# coordinators-playground
SwiftUI Coordinators Playground

The DeepLink parsing expects the following JSON structure:

{
  "step": {
    "transition": {
      "flow": {
        "tabs": {}
      }
    }
  },
  "children": [
    {
      "step": {
        "change": {
          "tab": {
            "home": {}
          }
        }
      },
      "children": [
        {
          "step": {
            "push": {
              "path": {
                "screenA": {}
              }
            }
          },
          "children": []
        },
        {
          "step": {
            "push": {
              "path": {
                "screenB": {
                  "id": 1
                }
              }
            }
          },
          "children": []
        },
        {
          "step": {
            "push": {
              "path": {
                "screenC": {}
              }
            }
          },
          "children": []
        },
        {
          "step": {
            "present": {
              "destination": {
                "account": {
                  "authToken": "secretToken"
                }
              }
            }
          },
          "children": [
            {
              "step": {
                "push": {
                  "path": {
                    "accountDetails": {}
                  }
                }
              },
              "children": []
            }
          ]
        }
      ]
    }
  ]
}

This will set the Root flow to be MainTabsCoordinator, set the Tab of MainTabsCoordinator to HomeCoordinator, push ScreenA, ScreenB and ScreenC to the NavigationStack of HomeCoordinator, await the login process and after it is done present the AccountCoordinator modally and push AccountDetails onto the AccountCoordinator's stack.

The application expects this JSON format to be encoded into Base64 and attach to a url. The Base64 representation of the above format with trimmed whitespaces looks like this:

eyJzdGVwIjp7InRyYW5zaXRpb24iOnsiZmxvdyI6eyJ0YWJzIjp7fX19fSwiY2hpbGRyZW4iOlt7InN0ZXAiOnsiY2hhbmdlIjp7InRhYiI6eyJob21lIjp7fX19fSwiY2hpbGRyZW4iOlt7InN0ZXAiOnsicHVzaCI6eyJwYXRoIjp7InNjcmVlbkEiOnt9fX19LCJjaGlsZHJlbiI6W119LHsic3RlcCI6eyJwdXNoIjp7InBhdGgiOnsic2NyZWVuQiI6eyJpZCI6MX19fX0sImNoaWxkcmVuIjpbXX0seyJzdGVwIjp7InB1c2giOnsicGF0aCI6eyJzY3JlZW5DIjp7fX19fSwiY2hpbGRyZW4iOltdfSx7InN0ZXAiOnsicHJlc2VudCI6eyJkZXN0aW5hdGlvbiI6eyJhY2NvdW50Ijp7ImF1dGhUb2tlbiI6InNlY3JldFRva2VuIn19fX0sImNoaWxkcmVuIjpbeyJzdGVwIjp7InB1c2giOnsicGF0aCI6eyJhY2NvdW50RGV0YWlscyI6e319fX0sImNoaWxkcmVuIjpbXX1dfV19XX0=

The fully created DeepLink command would look like this:

xcrun simctl openurl booted "coordinatorsplayground://deeplink?payload=eyJzdGVwIjp7InRyYW5zaXRpb24iOnsiZmxvdyI6eyJ0YWJzIjp7fX19fSwiY2hpbGRyZW4iOlt7InN0ZXAiOnsiY2hhbmdlIjp7InRhYiI6eyJob21lIjp7fX19fSwiY2hpbGRyZW4iOlt7InN0ZXAiOnsicHVzaCI6eyJwYXRoIjp7InNjcmVlbkEiOnt9fX19LCJjaGlsZHJlbiI6W119LHsic3RlcCI6eyJwdXNoIjp7InBhdGgiOnsic2NyZWVuQiI6eyJpZCI6MX19fX0sImNoaWxkcmVuIjpbXX0seyJzdGVwIjp7InB1c2giOnsicGF0aCI6eyJzY3JlZW5DIjp7fX19fSwiY2hpbGRyZW4iOltdfSx7InN0ZXAiOnsicHJlc2VudCI6eyJkZXN0aW5hdGlvbiI6eyJhY2NvdW50Ijp7ImF1dGhUb2tlbiI6InNlY3JldFRva2VuIn19fX0sImNoaWxkcmVuIjpbeyJzdGVwIjp7InB1c2giOnsicGF0aCI6eyJhY2NvdW50RGV0YWlscyI6e319fX0sImNoaWxkcmVuIjpbXX1dfV19XX0="


