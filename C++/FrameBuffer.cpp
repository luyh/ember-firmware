#include "FrameBuffer.h"

#include <Magick++.h>
#include <SDL/SDL.h>
#include <stdexcept>

#include "ErrorMessage.h"
#include "Logger.h"

FrameBuffer::FrameBuffer()
{
    // in case we exited abnormally before, 
    // tear down SDL before attempting to re-initialize it
    SDL_VideoQuit();
    
    if (SDL_Init(SDL_INIT_VIDEO) < 0)
    {
        TearDown();
        throw std::runtime_error(ErrorMessage::Format(SdlInit, SDL_GetError()));
    }

    // use the full screen to display the images
    _videoInfo = SDL_GetVideoInfo();

    // print out video parameters
    std::cout << "screen is " << _videoInfo->current_w <<
                 " x "        << _videoInfo->current_h <<
                 " x "        << (int)_videoInfo->vfmt->BitsPerPixel << "bpp" <<
                 std::endl;
   
    _screen = SDL_SetVideoMode(_videoInfo->current_w, _videoInfo->current_h, 
                               _videoInfo->vfmt->BitsPerPixel, 
                               SDL_SWSURFACE | SDL_FULLSCREEN);

    if (!_screen)
    {
        TearDown();
        throw std::runtime_error(ErrorMessage::Format(SdlSetMode, 
                                                            SDL_GetError()));
    }
    
    // create 8 bpp surface for displaying images
    _surface = SDL_CreateRGBSurface(0, _videoInfo->current_w , 
                                       _videoInfo->current_h, 8, 0, 255, 0, 0);
    
    if (!_surface) 
    {   
        TearDown();
        throw std::runtime_error(ErrorMessage::Format(SdlCreateSurface, 
                                                            SDL_GetError()));
    }
   
    // hide the cursor
    SDL_ShowCursor(SDL_DISABLE);
    if (SDL_ShowCursor(SDL_QUERY) != SDL_DISABLE)
    {
        // not a fatal error
        LOGGER.LogError(LOG_WARNING, errno, ERR_MSG(SdlHideCursor), 
                                                            SDL_GetError());
    }
}

FrameBuffer::~FrameBuffer()
{
    TearDown();
}

// Copies the green channel from the specified image into an auxiliary surface
// but does not display the result.
void FrameBuffer::Blit(Magick::Image& image)
{
    image.write(0, 0, _videoInfo->current_w, _videoInfo->current_h, "G",
                Magick::CharPixel, _surface->pixels);
}

// Sets all pixels of the frame buffer to the specified value and displays the
// result immediately.
void FrameBuffer::Fill(char value)
{
    if (SDL_MUSTLOCK(_screen) && SDL_LockSurface(_screen) != 0)
    {
        throw std::runtime_error(ErrorMessage::Format(SdlLockSurface,
                                                            SDL_GetError()));
    }
    
    if (SDL_FillRect(_screen, NULL, value) != 0)
    {
        throw std::runtime_error(ErrorMessage::Format(SdlFillRect,
                                                            SDL_GetError()));
    }
  
    if (SDL_MUSTLOCK(_screen))
    {
        SDL_UnlockSurface(_screen);
    }

    if (SDL_Flip(_screen) != 0)
    {
        throw std::runtime_error(ErrorMessage::Format(SdlFlip, SDL_GetError()));
    }
}

// Displays the contents of the auxiliary surface immediately.
void FrameBuffer::Swap()
{
    if (SDL_BlitSurface(_surface, NULL, _screen, NULL) != 0)
    {
        throw std::runtime_error(ErrorMessage::Format(SdlBlitSurface,
                                                            SDL_GetError()));
    }

    if (SDL_Flip(_screen) != 0)
    {
        throw std::runtime_error(ErrorMessage::Format(SdlFlip, SDL_GetError()));
    }
}

void FrameBuffer::TearDown()
{
    SDL_FreeSurface(_surface);
    SDL_VideoQuit();
    SDL_Quit();    
}
