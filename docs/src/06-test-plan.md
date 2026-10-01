---
title: "BabyShopHub"
subtitle: "Test Plan"
author: "Aptech eProject Submission"
date: "Version 1.0"
---

# 1. Purpose and scope

This Test Plan defines how BabyShopHub is verified against its requirements. It
sets out the testing strategy, the environment, a table of concrete test cases
covering every functional area, the entry and exit criteria for a verified
release, and how results are recorded.

**In scope:** every functional requirement FR-1 to FR-27 from the SRS, and the
security and error-handling non-functional requirements that can be exercised
through the UI.

**Out of scope:** real payment processing (checkout is simulated), any network
or multi-device behaviour (the app is entirely local), and formal accessibility
certification (which requires assistive-technology testing beyond this project).

\newpage

# 2. Testing strategy

Testing proceeds in two tiers, from cheapest to most authoritative.

**Tier 1 — Static analysis.** The project is checked with `flutter analyze`, the
Dart analyzer, which type-checks every file and flags invalid references, dead
code, and lint violations. The rules are configured in `analysis_options.yaml`
(the standard `flutter_lints` set). It should report `No issues found!`. This is
the first gate and is run after every change.

**Tier 2 — Manual functional testing.** With the app running
(`flutter run -d windows`), the test cases in Section 4 are executed by hand
against the seeded demo data, following the flows in the User Guide. Each case
lists the steps to take and the result to expect.

This two-tier approach is deliberate: static analysis catches code-level errors
early and cheaply, and manual testing confirms that the running app behaves the
way the requirements specify.

\newpage

# 3. Test environment

| Item | Value |
|------|-------|
| Platform | Windows desktop (`flutter run -d windows`), or Android device/emulator |
| Build | Debug build via `flutter run` |
| Data | The database seeded on first launch (see Developer Guide §6) |
| Customer account | `parent@babyshophub.com` / `Parent@123` |
| Admin account | `admin@babyshophub.com` / `Admin@123` |
| Reset between runs | Delete the local database file (app rebuilds seed data) |

\newpage

# 4. Functional test cases

Each case lists what to do and what should happen, with the requirement it
covers. IDs are grouped by area.

## 4.1 Authentication and accounts

| ID | Test | Expected result | Req |
|----|------|-----------------|-----|
| TC-01 | Register with valid details | Account created, signed in, Home shown | FR-1 |
| TC-02 | Register with a weak password (e.g. "abc") | Rejected with a validation message; no account created | FR-1, NFR-4 |
| TC-03 | Register with an email already in use | Rejected with a clear "email already registered" message | FR-1 |
| TC-04 | Log in with correct customer credentials | Storefront (customer shell) opens | FR-2 |
| TC-05 | Log in with correct admin credentials | Admin panel opens | FR-2 |
| TC-06 | Log in with a wrong password | Rejected with an error; not signed in | FR-2 |
| TC-07 | Close and reopen the app while signed in | Session restored; returns to the correct home | FR-3 |
| TC-08 | Sign out | Returns to login; session cleared | FR-4 |
| TC-09 | Edit profile name/phone; add and default an address | Changes saved and reflected at checkout | FR-5 |

## 4.2 Catalogue, search, and reviews

| ID | Test | Expected result | Req |
|----|------|-----------------|-----|
| TC-10 | Open Categories and enter one | Products in that category are listed | FR-6 |
| TC-11 | Search by product name | Matching products shown | FR-7 |
| TC-12 | Search by brand | Matching products shown | FR-7 |
| TC-13 | Apply price/rating/availability filters and a sort | Result set narrows and reorders accordingly | FR-7 |
| TC-14 | Open a product detail | Image, price, brand, stock, seller, rating, reviews shown | FR-8, FR-9 |
| TC-15 | Write a review on a delivered product | Review appears; product average updates | FR-10 |
| TC-16 | Rate a seller | Seller rating recorded separately from product reviews | FR-10 |

## 4.3 Cart, checkout, and payment

| ID | Test | Expected result | Req |
|----|------|-----------------|-----|
| TC-17 | Add a product to the cart | Cart badge increments | FR-11 |
| TC-18 | Increase quantity beyond stock | Plus button stops at available stock | FR-11, NFR-4 |
| TC-19 | Change quantity and remove an item in the cart | Totals recompute; item removed | FR-12 |
| TC-20 | Observe free-delivery hint | Cart shows how much more to add; delivery becomes free above threshold | FR-12 |
| TC-21 | Proceed to checkout | Order summary shows items, address, and price breakdown | FR-13 |
| TC-22 | Enter a malformed card number | Rejected with a validation message | FR-14, NFR-4 |
| TC-23 | Complete checkout with a well-formed card | Order confirmation with reference; cart emptied | FR-14, FR-15 |

## 4.4 Orders and tracking

| ID | Test | Expected result | Req |
|----|------|-----------------|-----|
| TC-24 | Open Orders after placing one | New order listed with status Pending | FR-16 |
| TC-25 | Open an order's detail | Tracking timeline with dated status stages shown | FR-17 |
| TC-26 | Cancel an order before Shipped | Order becomes Cancelled; Cancel hidden once Shipped | FR-17 |

## 4.5 Support

| ID | Test | Expected result | Req |
|----|------|-----------------|-----|
| TC-27 | Read the FAQ | Help topics displayed | FR-20 |
| TC-28 | Open a support ticket | Ticket created in Open status | FR-18 |
| TC-29 | Exchange messages on a ticket | Messages appear in the conversation | FR-19 |

## 4.6 Administration

| ID | Test | Expected result | Req |
|----|------|-----------------|-----|
| TC-30 | Open the admin dashboard | Summary counts/figures shown | FR-21 |
| TC-31 | Create a product with valid data | Product added; visible in storefront | FR-22 |
| TC-32 | Save a product with an empty name or bad price | Rejected with a validation message | FR-22, NFR-4 |
| TC-33 | Advance an order Pending → Confirmed → … → Delivered | Only valid next steps offered; each recorded on the timeline | FR-24 |
| TC-34 | Delete a category that still has products | Refused with an explanation | FR-23 |
| TC-35 | Delete an empty category | Removed | FR-23 |
| TC-36 | Suspend a customer, then attempt login as them | Login refused while suspended; restore re-enables | FR-25, NFR-5 |
| TC-37 | Attempt to suspend the last active admin | Refused to protect management access | FR-25 |
| TC-38 | Hide, restore, and delete a review | Hidden review leaves the storefront and rating; delete removes it | FR-26 |
| TC-39 | Reply to a ticket and change its status | Reply reaches the customer; status updates (incl. reopen) | FR-27 |

\newpage

# 5. Non-functional test cases

| ID | Test | Expected result | Req |
|----|------|-----------------|-----|
| TC-40 | Time common actions (open screen, search, add to cart) | Each completes within ~1–2 seconds; no network wait | NFR-1 |
| TC-41 | Trigger validation errors across forms | Every failure shows a clear, human-readable message; no crash | NFR-4 |
| TC-42 | Inspect stored password (e.g. via the DB file) | Stored as a salted SHA-256 hash, never plain text | NFR-5 |
| TC-43 | Attempt to reach admin features as a customer | Not reachable; admin shell is never presented to a customer | NFR-5 |
| TC-44 | Run `flutter analyze` | Reports `No issues found!` | NFR-7 |

\newpage

# 6. Entry and exit criteria

**Entry criteria.** The app builds and launches (Setup Guide completed), and the
seeded demo data is present.

**Exit criteria.** The release is considered verified when:

- all functional cases TC-01 to TC-39 pass;
- the core journeys pass end to end — customer register-to-order (TC-01, TC-17,
  TC-21, TC-23) and admin order fulfilment (TC-33);
- the security cases pass — salted-hash storage (TC-42), access separation
  (TC-43), suspended-login refusal (TC-36), last-admin protection (TC-37);
- `flutter analyze` reports no issues (TC-44).

Any failing case is logged with its ID, the steps, the observed result, and a
screenshot, and is re-tested after a fix.

\newpage

# 7. Recording and reporting results

Each test case is run in order and its outcome recorded against its ID as
**Pass** or **Fail**. A convenient way to keep the record is a simple table:

| Field | What to note |
|-------|--------------|
| Test ID | The case run, e.g. TC-23 |
| Result | Pass or Fail |
| Notes | For a failure: the exact steps, what was expected, and what happened |
| Evidence | A screenshot of the screen at the point of interest |

A failing case is logged with these details, fixed, and then re-run to confirm
the fix before the release is considered verified against Section 6.

*Executing TC-01 through TC-44 against the running app completes verification of
the requirements defined in the SRS.*
