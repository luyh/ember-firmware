/* 
 * File:   EventHandler.h
 * Author: greener
 *
 * Created on March 31, 2014, 1:48 PM
 */

#ifndef EVENTHANDLER_H
#define	EVENTHANDLER_H

#include <Event.h>
#include <vector>
#include <Hardware.h>

class EventHandler
{
public:
    EventHandler();
    ~EventHandler();
    void Subscribe(EventType eventType, EventCallback callback);
    void Begin();
    
    
private:
    /// array of collections of callbacks for each event type
    std::vector<EventCallback> _callbacks[InvalidEventType];
    
    /// file descriptors for receiving each event type
    int _fileDescriptors[InvalidEventType];
    
    int GetInterruptDescriptor(EventType eventType);
    
};


#endif	/* EVENTHANDLER_H */
