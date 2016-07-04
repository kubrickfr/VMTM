# VMTM
QOS control script for OpenWRT to beat the side effects of VirginMedia™ (UK ISP) Traffic-Management-induced buffer bloat

**Disclaimer**: *The following statements express my opinion only and come from my observations of how the system reacts. Call it "reverse engineering" if you like, but I have no inside knowledge: it may not reflect how VirginMedia's internal network really works or even their intentions.* This is not supported or endorsed in any way by VirginMedia™.

If this project is useful to customers of other service providers, please let me know (with references to their traffic management policies) and I will add them to this documentation.

## How does VirginMedia™ (UK) Traffic management work

### What VirginMedia™ tells you

Please refer to VirginMedia's guide to traffic management [30Mb or higher](https://my.virginmedia.com/traffic-management/traffic-management-policy-30Mb-or-higher.html) or [20Mb or lower](https://my.virginmedia.com/traffic-management/traffic-management-policy-20Mb-or-lower.html) to understand how it works.
For the actual rates and thresholds, refer to their [thresholds](https://my.virginmedia.com/traffic-management/traffic-management-policy-thresholds.html) page, you will need to edit the script with the limits that apply to your offer.

### What they don't tell you... (aka "the Dark Side")

Despite making endearing statements [like](https://my.virginmedia.com/traffic-management/traffic-management-policy-30Mb-or-higher.html):
> After listening to your feedback, we've decided to stop applying our traffic management policy to download speeds. So now you can download as much as you like without worrying about traffic management slowing you down.

The way they implement their traffic management policies indeed leads to a massive drop in the download rate despite, it is true, not limiting the download rate **at all**.

How comes? Well, in normal time, your ulpload is limited by your modem's uplink sync speed, but when they start "managing" your upload bandwidth on their network (rather than on the modem), they also introduce a rather large buffer in which your outgoing packets are going to be queued before eventually being sent, or dropped if you keep saturating your upload bandwidth. A good intention, don’t you think? If don’t see what’s wrong with that, go read about [buffer bloat](http://www.bufferbloat.net/projects/bloat/wiki/Introduction) and come back here when you’re done!

In a nutshell, if you keep uploading like crazy:
* Your ping will rise to very long round trip times (as much as a full second)
* As a result of this “unnatural” latency, your Operating System’s [TCP congestion avoidance algorithm](https://en.wikipedia.org/wiki/TCP_congestion-avoidance_algorithm) will not work correctly
* Because of that your download rates will suffer greatly

Good bye online games, VOIP, fast browsing, etc…

## What this script does **not** do

It does **not** work around any bandwidth limitation

## What this script does

**If** you use your (rather pathetic) SuperHub as a modem only (and it is actually a perfectly fine piece of hardware when used in this configuration) and use a router running [OpenWRT](https://openwrt.org/), then you can use this script to:

1. Detect when VirginMedia applies traffic management measures to your line by measuring the RTT to your gateway
2. When traffic management is detected, do the bandwidth limitation ourselves with OpenWRT’s QOS module.

The effect is that your upload bandwidth will essentially stay the same but outgoing packets in excess of the available upload bandwidth will almost instantly be dropped, resulting in your Operating System’s TCP congestion avoidance algorithm working correctly and miraculously faster download speeds.

### For example:

Uploading large files for hours, 9 simultaneous streams, test made at around 8PM on a Monday:

Without VMTM:

![Alt text](/img/noVMTM.png?raw=true "")

With VMTM:

![Alt text](/img/VMTM.png?raw=true "")


## How to use it?

Once OpenWRT is working correctly and QOS support is installed and enabled, simply copy the virgin.sh script in your router’s /root/ directory or anywhere else you like, edit the first 3 variables to suit [your needs](https://my.virginmedia.com/traffic-management/traffic-management-policy-thresholds.html) and then create a crontab entry to run the script every 5 minues, all the time. Mine looks like this:

```
PATH=/usr/bin:/usr/sbin:/bin:/sbin
*/5 * * * * /root/virgin.sh
```

I’ve been using this script (or previous versions) since the end of 2014 and it’s served me well since then. It’s easy to forget it’s there, and for me it just works. I’ve now (February 2016) decided to open-source it and welcome contributions.

I’m aware of the SQM/Smart Queue Management package in OpenWRT, but using QOS works as well and let you do more, like making sure that your DNS queries have priority, and that also makes a big difference in a traffic management situation, but the configuration of QOS is outside the scope of this project’s documentation.
