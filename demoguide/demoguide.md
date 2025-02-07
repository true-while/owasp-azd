[comment]: <> (please keep all comment items at the top of the markdown file)
[comment]: <> (please do not change the ***, as well as <div> placeholders for Note and Tip layout)
[comment]: <> (please keep the ### 1. and 2. titles as is for consistency across all demoguides)
[comment]: <> (section 1 provides a bullet list of resources + clarifying screenshots of the key resources details)
[comment]: <> (section 2 provides summarized step-by-step instructions on what to demo)


[comment]: <> (this is the section for the Note: item; please do not make any changes here)
***
### Azure Event Hub publisher subscriber communication - demo scenario

<div style="background: lightgreen; 
            font-size: 14px; 
            color: black;
            padding: 5px; 
            border: 1px solid lightgray; 
            margin: 5px;">

**Note:** Below demo steps should be used **as a guideline** for doing your own demos. Please consider contributing to add additional demo steps.
</div>

[comment]: <> (this is the section for the Tip: item; consider adding a Tip, or remove the section between <div> and </div> if there is no tip)

<div style="background: lightblue; 
            font-size: 14px; 
            color: black;
            padding: 5px; 
            border: 1px solid lightgray; 
            margin: 5px;">

**Tip:** 
1. This scenario can be used in AZ-204 Developing Azure Solutions and can demonstrate the basics of communication between apps by using a _broker_ (Event Hub) deployed in Azure.

2. The demo scenario may require the following ports for communication: 5671/5672 TCP.

3. **Subscriber** will automatically exit after 30 seconds of listening for events. PLease _do not close the console window_ before exit to let the application properly release resources when disconnected. 

4. The console application compiled with deployment will use environment variables configured with values during deployment such as Event Hub connection string and Azure Storage Account connection string.

5. Event capture functionality _starts automatically for 15 min_ only right after completion of the provisioning scenario. If you want to restart event capturing you can do that manually from the Azure portal.
</div>

***
### 1. Demo scenario

Publisher application ...


### 5. References.

1. [Feature of Event Hub](https://learn.microsoft.com/en-us/azure/event-hubs/event-hubs-features)
2. [SDK library Azure.Messaging.EventHubs and code examples](https://www.nuget.org/packages/Azure.Messaging.EventHubs/)
3. [Event Hub code samples](https://learn.microsoft.com/en-us/azure/event-hubs/event-hubs-samples) 
4. [Event stream capturing](https://learn.microsoft.com/en-us/azure/event-hubs/explore-captured-avro-files)
2. [AVRO format documentation](https://avro.apache.org/docs/)


[comment]: <> (this is the closing section of the demo steps. Please do not change anything here to keep the layout consistent with the other demoguides.)
<br></br>
***
<div style="background: lightgray; 
            font-size: 14px; 
            color: black;
            padding: 5px; 
            border: 1px solid lightgray; 
            margin: 5px;">

**Note:** This is the end of the current demo guide instructions.
</div>




