﻿class Maths < BotPlugin
    def initialize
        # Authorisations
        @reqAuthLevel = 0

        # Strings
        @noAuthMessage = "You are not authorised for this."

        # Required plugin stuff
        name = self.class.name
        @hook = ["math", "maths"]
        processEvery = false
        help = "Usage: #{@hook} <term>\nFunction: Evaluates basic mathematical expressions. Accepts +, -, /, *, ^, ** and % as operators."
        super(name, @hook, processEvery, help)
    end

    def main(data)
        @givenLevel = data["authLevel"]

        if authCheck(@reqAuthLevel)
            return sayf(reversePolishNotation(shuntInput(formatInput(stripWordsFromStart(data["message"], 1)))))
        else
            return sayf(@noAuthMessage)
        end
    rescue => e
        handleError(e)
        return sayf(e)
    end

    def shuntInput(s)
        # According to http://en.wikipedia.org/wiki/Shunting-yard_algorithm#The_algorithm_in_detail
        stack = []
        outputQueue = []

        s.each { |token|
            if  isNumber?(token)
                outputQueue.push(token)
            elsif isOperator?(token)
                while isOperator?(stack.last) && 
                        (
                            (getPrecedence(token)[:a] == 'left' && (getPrecedence(token)[:p] <= getPrecedence(stack.last)[:p])) ||
                            (getPrecedence(token)[:a] == 'right' && (getPrecedence(token)[:p] < getPrecedence(stack.last)[:p]))
                        )
                    outputQueue.push(stack.pop)
                end
                stack.push(token)
            elsif token == '('
                stack.push(token)
            elsif token == ')'
                while stack.last != '('
                    outputQueue.push(stack.pop)
                    
                    if stack.size == 0
                        raise "Syntax Error: Mismatched parentheses"
                    end
                end
                
                stack.pop if stack.last == '('
            end
        }

        while stack.size > 0
            if stack.last == '('
                raise "Syntax Error: Mismatched parentheses"
            else
                outputQueue.push(stack.pop)
            end
        end

        puts "Shunted: #{outputQueue.join(' ')}"
        return outputQueue
    end

    def reversePolishNotation(expr)
        # According to http://en.wikipedia.org/wiki/Reverse_polish_notation#Postfix_algorithm
        stack = []

        while expr.size > 0
            if isNumber?(expr.first)
                stack.push(expr.shift.to_f)
            else
                # If fewer values than function/operator's arguments
                raise 'Syntax Error: Insufficient values' if stack.size < 2

                rightVal = stack.pop
                leftVal = stack.pop
                stack.push(leftVal.send(expr.first, rightVal))
                expr.shift
            end
            
            puts "RPN: Stack: #{stack.join(" ")} Expression: #{expr.join(" ")}"
        end
        
        return stack[0]
    end

    def getPrecedence(c)
        case c
        when '^' then
            return {p: 4, a: 'right'}
        when '**' then
            return {p: 4, a: 'right'}
        when '*' then
            return {p: 3, a: 'left'}
        when '/' then
            return {p: 3, a: 'left'}
        when '+' then
            return {p: 2, a: 'left'}
        when '-' then
            return {p: 2, a: 'left'}
        when '%' then
            return {p: 3, a: 'left'}
        else
            return {p: 0, a: 'left'}
        end
    end

    def isOperator?(c)
        if /(\^|\*\*|\*|\/|\+|\-|\%)/ === c
            return true
        else
            return false
        end
    end

    def isNumber?(s)
        if /\d+(.\d+)?/ === s
            return true
        else
            return false
        end
    end

    def formatInput(s)
        s.gsub!(/ /, '')
        s.gsub!('*', ' * ')
        s.gsub!('^', ' ** ')
        s.gsub!(' *  * ', ' ** ')
        s.gsub!('+', ' + ')
        s.gsub!('-', ' - ')
        s.gsub!('/', ' / ')
        s.gsub!('%', ' % ')
        s.gsub!('(', ' ( ')
        s.gsub!(')', ' ) ')
        s = s.split(' ')
        
        return s
    end
end