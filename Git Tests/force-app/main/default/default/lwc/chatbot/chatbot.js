import BaseChatMessage from 'lightningsnapin/baseChatMessage';

const CHAT_CONTENT_CLASS = 'chat-content';
const AGENT_USER_TYPE = 'agent';
const CHASITOR_USER_TYPE = 'chasitor';
const SUPPORTED_USER_TYPES = [AGENT_USER_TYPE, CHASITOR_USER_TYPE];

/**
 * Displays a chat message that replaces links with custom text.
 */
export default class ShortenedLinksSample extends BaseChatMessage {
    
    nps = false;
    html = false;
    documentDownload = false;

    messageStyle = '';
    text = '';

    isSupportedUserType(userType) {
        return SUPPORTED_USER_TYPES.some((supportedUserType) => supportedUserType === userType);
    }

    connectedCallback() {

        this.text = this.messageContent.value;
        if (this.isSupportedUserType(this.userType)) {

            if (this.userType == 'agent' && this.text.startsWith('lwc:nps')) {
                this.nps = true;
            }  else if (this.userType == 'agent' && this.text.startsWith('lwc:docDown')) {
                this.messageStyle = `${CHAT_CONTENT_CLASS} ${this.userType}`;
                this.documentDownload = true;
            } else if (!this.text.startsWith('lwc:hide')) {
                this.html = true;
                this.messageStyle = `${CHAT_CONTENT_CLASS} ${this.userType}`;
            }
            
        } else {
            throw new Error(`Unsupported user type passed in: ${this.userType}`);
        }
    }

    handlePostMessage(event) 
    {
        const dateValue = event.detail;
        console.log('Handling Event with value: ' + dateValue);
        window.postMessage(
            {
                message: dateValue,
                type: "chasitor.sendMessage"
            },
            window.parent.location.href
        );
    }    
}