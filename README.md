# Handling Deep Links

This document explains the structure and usage of deep links within the application.

## 🔗 Deep Link Structure

The deep-linking mechanism uses a hierarchical JSON structure to define a sequence of navigation steps. The payload is a `JSON` object containing a `step` and an optional array of `children`. Each `step` corresponds to a specific navigation action (e.g., `transition`, `push`, `present`).

Here is a sample `JSON` payload that illustrates a complex deep-linking scenario:

```json
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
```

### 📍 Example Navigation Path

The `JSON` structure above performs the following navigation sequence:

  * **`Root`** -\> `transition` to **`MainTabsCoordinator`**.
  * **`MainTabsCoordinator`** -\> `change` to **`HomeCoordinator`** (selecting the home tab).
  * **`HomeCoordinator`** -\> `push`es **`ScreenA`**, **`ScreenB`**, and **`ScreenC`** onto its navigation stack.
  * **`HomeCoordinator`** -\> `present`s the **`AccountCoordinator`** modally.
  * **`AccountCoordinator`** -\> `push`es **`AccountDetails`** onto its navigation stack.

## ⚙️ Usage

The application expects the `JSON` payload to be **Base64-encoded** and attached as a query parameter in a URL.

### Base64 Encoding

The Base64 representation of the `JSON` above (with trimmed whitespace) is:

```
eyJzdGVwIjp7InRyYW5zaXRpb24iOnsiZmxvdyI6eyJ0YWJzIjp7fX19fSwiY2hpbGRyZW4iOlt7InN0ZXAiOnsiY2hhbmdlIjp7InRhYiI6eyJob21lIjp7fX19fSwiY2hpbGRyZW4iOlt7InN0ZXAiOnsicHVzaCI6eyJwYXRoIjp7InNjcmVlbkEiOnt9fX19LCJjaGlsZHJlbiI6W119LHsic3RlcCI6eyJwdXNoIjp7InBhdGgiOnsic2NyZWVuQiI6eyJpZCI6MX19fX0sImNoaWxkcmVuIjpbXX0seyJzdGVwIjp7InB1c2giOnsicGF0aCI6eyJzY3JlZW5DIjp7fX19fSwiY2hpbGRyZW4iOltdfSx7InN0ZXAiOnsicHJlc2VudCI6eyJkZXN0aW5hdGlvbiI6eyJhY2NvdW50Ijp7ImF1dGhUb2tlbiI6InNlY3JldFRva2VuIn19fX0sImNoaWxkcmVuIjpbeyJzdGVwIjp7InB1c2giOnsicGF0aCI6eyJhY2NvdW50RGV0YWlscyI6e319fX0sImNoaWxkcmVuIjpbXX1dfV19XX0=
```

### Deep Link URL

The full deep link URL to open in a simulator would look like this:

```
xcrun simctl openurl booted "coordinatorsplayground://deeplink?payload=eyJzdGVwIjp7InRyYW5zaXRpb24iOnsiZmxvdyI6eyJ0YWJzIjp7fX19fSwiY2hpbGRyZW4iOlt7InN0ZXAiOnsiY2hhbmdlIjp7InRhYiI6eyJob21lIjp7fX19fSwiY2hpbGRyZW4iOlt7InN0ZXAiOnsicHVzaCI6eyJwYXRoIjp7InNjcmVlbkEiOnt9fX19LCJjaGlsZHJlbiI6W119LHsic3RlcCI6eyJwdXNoIjp7InBhdGgiOnsic2NyZWVuQiI6eyJpZCI6MX19fX0sImNoaWxkcmVuIjpbXX0seyJzdGVwIjp7InB1c2giOnsicGF0aCI6eyJzY3JlZW5DIjp7fX19fSwiY2hpbGRyZW4iOltdfSx7InN0ZXAiOnsicHJlc2VudCI6eyJkZXN0aW5hdGlvbiI6eyJhY2NvdW50Ijp7ImF1dGhUb2tlbiI6InNlY3JldFRva2VuIn19fX0sImNoaWxkcmVuIjpbeyJzdGVwIjp7InB1c2giOnsicGF0aCI6eyJhY2NvdW50RGV0YWlscyI6e319fX0sImNoaWxkcmVuIjpbXX1dfV19XX0="
```
