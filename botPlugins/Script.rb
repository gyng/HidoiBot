﻿# Dangerous!

class Script < BotPlugin
    def initialize
        # Authorisations
        @reqScriptLevel = 3
        
        # Strings
        @noAuthMessage = 'You are not authorised for this.'
        
        # Required plugin stuff
        name = self.class.name
        @hook = 'script'
        processEvery = false
        help = "Usage: #{@hook} <term>\nFunction: Evaluates term."
        super(name, @hook, processEvery, help)
    end
    
    def main(data)
        @givenLevel = data["authLevel"]
        toEval = stripTrigger(data)
        mode = arguments(data)[0]
        
        if authCheck(@reqScriptLevel)
            rs = eval(toEval)
            return rs
        end
    rescue => e
        handleError(e)
        return sayf(e)
    end
end