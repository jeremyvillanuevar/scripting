#if defined _bytebuffer_included
 #endinput
#endif
#define _bytebuffer_included

#define BYTEBUFFER_VERSION 3

#if !defined MAX_BUFFER_LENGTH
 #define MAX_BUFFER_LENGTH 1024
#endif

enum Endianness {
    LittleEndian,
    BigEndian,
}

enum struct ByteBuffer {
    // Current cursor position
    int iCursor;

    // Byte order
    Endianness eEndian;

    // Data buffer
    char cBuffer[MAX_BUFFER_LENGTH];

    void WriteByte(int data) {
        this.cBuffer[this.iCursor] = data & 0x000000FF;
        this.iCursor++;
    }

    void WriteShort(int data) {
        switch (this.eEndian) {
            case LittleEndian:
                this.WriteByte(data & 0x000000FF);
                this.WriteByte((data & 0x0000FF00) >> 8);
            case BigEndian:
                this.WriteByte((data & 0x0000FF00) >> 8);
                this.WriteByte(data & 0x000000FF);
        }
    }

    void WriteInt(int data) {
        switch (this.eEndian) {
            case LittleEndian:
                this.WriteByte(data & 0x000000FF);
                this.WriteByte((data & 0x0000FF00) >> 8);
                this.WriteByte((data & 0x00FF0000) >> 16);
                this.WriteByte((data & 0xFF000000) >> 24);
            case BigEndian:
                this.WriteByte((data & 0xFF000000) >> 24);
                this.WriteByte((data & 0x00FF0000) >> 16);
                this.WriteByte((data & 0x0000FF00) >> 8);
                this.WriteByte(data & 0x000000FF);
        }
    }

    void WriteString(const char[] input) {
        int length = strlen(input);

        for(int i = 0; i < length; i++) {
            this.WriteByte(view_as<int>(input[i]));
        }
    }

    void WriteCString(const char[] input) {
        this.WriteString(input);
        this.WriteByte(0);
    }

    int ReadByte() {
        int value = this.cBuffer[this.iCursor] & 0xFF;
        this.iCursor++;
        return value;
    }

    int ReadShort() {
        int a, b;

        switch (this.eEndian) {
            case LittleEndian:
                a = this.ReadByte();
                b = (this.ReadByte() << 8) & 0x0000FF00;
            case BigEndian:
                a = (this.ReadByte() << 8) & 0x0000FF00;
                b = this.ReadByte();
        }

        return (a | b);
    }

    int ReadInt() {
        int a, b, c, d;

        switch (this.eEndian) {
            case LittleEndian:
                a = this.ReadByte();
                b = (this.ReadByte() << 8) & 0x0000FF00;
                c = (this.ReadByte() << 16) & 0x00FF0000;
                d = (this.ReadByte() << 24) & 0xFF000000;
            case BigEndian:
                a = (this.ReadByte() << 24) & 0xFF000000;
                b = (this.ReadByte() << 16) & 0x00FF0000;
                c = (this.ReadByte() << 8) & 0x0000FF00;
                d = this.ReadByte();
        }

        return (a | b | c | d);
    }

    int ReadCString(char[] output, int maxlen) {
        for(int i = 0; i < maxlen; i++) {
            output[i] = this.ReadByte();
            
            if(output[i] == '\0') {
                return i + 1;
            }
        }

        return maxlen;
    }

    int Dump(char[] output, int maxlen) {
        if(maxlen > this.Cursor) {
            maxlen = this.Cursor;
        }

        int i;

        for(i = 0; i < maxlen; i++) {
            output[i] = g_Buffer[this][i];
        }

        return i;
	}

    int Append(ByteBuffer buffer) {
        int length = buffer.iCursor;
        char[] dumped = new char[length];

        buffer.Dump(dumped, length);

        for(int i = 0; i < length; i++) {
            this.WriteByte(dumped[i]);
        }

        return length;
	}

    ByteBuffer Extract(int length) {
        ByteBuffer output;

        output.eEndian = this.eEndian;

        for(int i = 0; i < length; i++) {
            output.WriteByte(this.ReadByte());
        }

        output.iCursor = 0;

        return output;
	}

    void Reset() {
        this.iCursor = 0;
    }
}