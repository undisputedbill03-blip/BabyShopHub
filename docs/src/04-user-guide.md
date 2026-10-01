---
title: "BabyShopHub"
subtitle: "User Guide — Shopping and Administration"
author: "Aptech eProject Submission"
date: "Version 1.0"
---

# 1. Welcome

BabyShopHub is a shopping app for everything a baby needs — diapers, food,
clothing, bath and feeding items, and toys. This guide shows you how to use it,
first as a **shopper** and then as an **administrator**. You do not need any
technical knowledge to follow it.

If the app is not yet running on your machine, follow the *Windows Setup Guide*
first. This guide assumes you are looking at the login screen.

## 1.1 The two demo accounts

The app comes pre-loaded with sample products and two ready-made accounts so you
can try everything immediately. Both are shown on the login screen — you can tap
one to fill it in.

| Role | Email | Password |
|------|-------|----------|
| Customer (shopper) | `parent@babyshophub.com` | `Parent@123` |
| Administrator (manager) | `admin@babyshophub.com` | `Admin@123` |

Logging in with the customer account opens the **shop**. Logging in with the
administrator account opens the **management panel**. The rest of this guide is
split the same way.

\newpage

# 2. Part One — Using the shop (Customer)

## 2.1 Creating an account

You can use the demo customer account above, or make your own:

1. On the login screen, tap **Create account**.
2. Enter your name, email, phone number, and a password. The password must be
   at least 8 characters and include at least one letter and one digit.
3. Tap **Create account**. You are signed in immediately and taken to the Home
   screen.

## 2.2 Finding things to buy

You have three ways to find products:

- **Search.** Use the search bar at the top of the Home screen to type a
  product name or brand.
- **Browse categories.** Open the **Categories** tab to see all departments
  (Diapers, Feeding, Clothing, Toys, and so on) and tap into one.
- **Filter and sort.** On any product list you can narrow by category, price
  range, minimum rating, and availability, and sort by price, rating, or
  newest.

Tap any product to open its detail page, where you can read its description,
price, stock, seller, average rating, and customer reviews.

## 2.3 Tutorial: place your first order

This is the main shopping flow from start to finish.

1. Find a product (Section 2.2) and open it.
2. Choose a quantity and tap **Add to cart**. A badge on the **Cart** tab
   updates to show the item is in.
3. Open the **Cart** tab. Check your items. Use the minus and plus buttons to
   change a quantity, or the bin icon to remove something. The cart shows your
   running **subtotal**, and tells you how much more to add to earn free
   delivery.
4. Tap **Checkout**.
5. On the checkout screen, confirm your **delivery address** (add one if you
   have none) and review the full price breakdown: subtotal, delivery, tax, and
   total.
6. Enter card details on the **payment** step. This is a demonstration — no real
   payment is taken (see the FAQ "Is my card charged?"). The card is checked for
   correct format only.
7. Tap **Place order**. You see an **order confirmation** with your order
   reference, and your cart is emptied.

Your new order now appears under the **Orders** tab with the status *Pending*.

## 2.4 Tutorial: track an order

1. Open the **Orders** tab from the bottom bar.
2. Tap the order you want to follow.
3. The **tracking timeline** shows every stage the order has reached — Pending,
   Confirmed, Packed, Shipped, Out for delivery, Delivered — each with the date
   and time it was recorded. The most recent stage is highlighted.

If the order has not yet been shipped, a **Cancel order** button is available
here; cancelling returns the items to stock.

## 2.5 Tutorial: leave a review

You can review a product once an order containing it is marked **Delivered**.

1. Open the delivered order from the **Orders** tab.
2. Tap **Write a review** next to the item.
3. Choose a star rating, add an optional title and comment, and submit.

Your review appears on the product's page and updates its average rating. You
have one review per product; editing it replaces your earlier one. To rate a
**seller**, open one of their products, tap the seller's name, then **Rate this
seller** — seller ratings are kept separate from product reviews.

## 2.6 Managing your profile

The **Profile** area (in the Account tab) lets you:

- edit your name and phone number;
- manage **delivery addresses** — save several, mark a default, and choose one
  at checkout;
- manage **saved cards** — only the brand and last four digits are ever stored;
- sign out.

## 2.7 Getting help

Open the **Support** area (from the Account tab) to:

- read the **FAQ** — answers to the common questions (reproduced in Section 4);
- open a **support ticket**: choose a category, enter a subject and message, and
  send it. An administrator replies inside the ticket, and you can carry on the
  conversation until it is resolved.

\newpage

# 3. Part Two — Managing the shop (Administrator)

Sign out and sign back in with the administrator account
(`admin@babyshophub.com` / `Admin@123`). You are taken to the admin panel, which
has a bottom bar with **Dashboard, Orders, Products, Support**, and a **More**
tab for everything else.

## 3.1 The dashboard

The **Dashboard** opens first and gives an at-a-glance summary of the shop —
key counts and figures so you can see activity without digging through lists.

## 3.2 Tutorial: fulfil an order

This is the counterpart to the customer's tracking view.

1. Open the **Orders** tab. You see every customer's orders with status and
   total.
2. Tap a **Pending** order to open it.
3. In **Update status**, tap the next stage. The app only offers the *permitted*
   next steps — you advance an order one stage at a time (Confirmed, then
   Packed, then Shipped, and so on).
4. Each change is recorded with a timestamp and instantly appears on the
   customer's tracking timeline.

You can **cancel** an order from here while it is still before *Shipped*; once
it is shipped, cancelling is no longer offered.

## 3.3 Tutorial: add or edit a product

1. Open the **Products** tab.
2. To edit, tap a product; to add, tap the **add** button.
3. Fill in the name, brand, description, price, stock, category, seller, and
   image, then save. Validation stops you saving an empty name or an invalid
   price or stock.
4. The change is reflected in the storefront immediately.

## 3.4 Managing categories

On the **More** tab, open **Categories** to add, rename, re-icon, or delete a
category. Each category shows how many products it contains. A category that
still has products **cannot** be deleted — move or reassign its products first.
This protects the storefront from empty or broken links.

## 3.5 Managing users

On the **More** tab, open **Users** to see every account. You can search, filter
by role, and **suspend** or **restore** a customer. A suspended customer cannot
sign in. The app prevents you from suspending the **last active administrator**,
so the shop can never lock itself out.

## 3.6 Moderating reviews

On the **More** tab, open **Reviews** to see all customer reviews. You can
**hide** a review (it stops counting toward the product's rating and disappears
from the storefront), **restore** it, or **delete** it outright. Use the
"Hidden only" filter to review what you have hidden.

## 3.7 Handling support tickets

Open the **Support** tab to see every customer ticket. Tap one to read the
conversation and **reply** — your first reply moves the ticket to *In progress*.
Use the status menu to mark a ticket **Resolved** or **Closed**, or to
**reopen** a closed ticket. Your replies appear on the customer's side of their
ticket instantly.

\newpage

# 4. Frequently asked questions

These are the questions answered inside the app, on the Support screen.

**How do I create an account?**
Tap Register on the welcome screen, enter your name, email address, phone number
and a password of at least eight characters containing a letter and a digit,
then tap Create account. You are signed in straight away.

**I forgot my password. What do I do?**
BabyShopHub stores all data on this device only, so there is no email reset
link. Contact support from this screen and an administrator can reset the
password on the account for you.

**How do I find a product?**
Use the search bar at the top of the Home screen to search by product name or
brand, or open Categories to browse. On the search results screen you can narrow
by category, price range, minimum rating and availability, and sort by price,
rating or newest.

**How do I change the quantity of something in my cart?**
Open the Cart tab and use the minus and plus buttons on the item. The plus
button stops at the quantity we have in stock. Swipe an item or tap the bin icon
to remove it.

**How much is delivery?**
Delivery is a flat fee that is shown on the checkout screen before you pay, and
it is free once your items total reaches the free-delivery threshold. The cart
tells you how much more you need to add to qualify.

**Is my card charged?**
No. Payment in this application is simulated for demonstration purposes. Only
the cardholder name, the card brand and the last four digits are saved, so we
can label your order; the full number is never stored and no security code is
ever collected. Nothing is sent to a bank or to any server.

**How do I track my order?**
Open Orders from the bottom bar and tap the order you want. The tracking
timeline shows every stage the parcel has reached, with the date and time each
stage was recorded.

**Can I cancel an order?**
Yes, while the order is still with us. The Cancel order button appears on the
order detail screen until the parcel is handed to the courier. Once the status
reaches Shipped it can no longer be cancelled from the app. Cancelling returns
the items to stock.

**When can I review a product?**
Once an order containing that product is marked Delivered. Open the order and
tap Write a review next to the item. You can give one review per product, and
editing it replaces your earlier one.

**How do I rate a seller?**
Open any product from that seller, tap the seller name to open their page, then
tap Rate this seller. Seller ratings are separate from product reviews so a
great product from a slow seller can be scored honestly on both.

**How do I change my delivery address?**
Go to Profile, then Delivery addresses. You can save several addresses, mark one
as the default, and pick a different one at checkout.

**Where is my data stored?**
Everything stays in a database file on this device. There is no account server
and nothing leaves the phone, so uninstalling the app removes your data
permanently.

\newpage

# 5. Quick tips

- **Tap a demo account** on the login screen to fill it in instantly.
- The **cart badge** always shows how many items you have — it updates the
  moment you add something.
- On the checkout screen, watch the **"add X more for free delivery"** hint to
  save on the delivery fee.
- As an administrator, you can only move an order **forward one stage at a
  time** — this mirrors how a real parcel travels and keeps the customer's
  tracking honest.
- To start completely fresh, uninstall and reinstall (or delete the local
  database file): the app rebuilds all the sample data on next launch.

*If a question is not answered here, open a support ticket in the app — that is
exactly the flow this guide's Section 2.7 and 3.7 describe.*
