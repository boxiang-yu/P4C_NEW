struct Version {
    bit<8> major;
    bit<8> minor;
}

error {
    NoError,
    PacketTooShort,
    NoMatch,
    EmptyStack,
    FullStack,
    OverwritingHeader
}

extern packet_in {
    void extract<T>(out T hdr);
    void extract<T>(out T variableSizeHeader, in bit<32> sizeInBits);
    T lookahead<T>();
    void advance(in bit<32> sizeInBits);
    bit<32> length();
}

extern packet_out {
    void emit<T>(in T hdr);
}

action NoAction() {
}
match_kind {
    exact,
    ternary,
    lpm
}

match_kind {
    range,
    selector
}

struct standard_metadata_t {
    bit<9>  ingress_port;
    bit<9>  egress_spec;
    bit<9>  egress_port;
    bit<32> clone_spec;
    bit<32> instance_type;
    bit<1>  drop;
    bit<16> recirculate_port;
    bit<32> packet_length;
}

extern Checksum16 {
    bit<16> get<D>(in D data);
}

enum CounterType {
    Packets,
    Bytes,
    Both
}

extern Counter {
    Counter(bit<32> size, CounterType type);
    void increment(in bit<32> index);
}

extern DirectCounter {
    DirectCounter(CounterType type);
}

extern Meter {
    Meter(bit<32> size, CounterType type);
    void meter<T>(in bit<32> index, out T result);
}

extern DirectMeter<T> {
    DirectMeter(CounterType type);
    void read(out T result);
}

extern Register<T> {
    Register(bit<32> size);
    void read(out T result, in bit<32> index);
    void write(in bit<32> index, in T value);
}

extern ActionProfile {
    ActionProfile(bit<32> size);
}

enum HashAlgorithm {
    crc32,
    crc16,
    random,
    identity
}

extern ActionSelector {
    ActionSelector(HashAlgorithm algorithm, bit<32> size, bit<32> outputWidth);
}

parser Parser<H, M>(packet_in b, out H parsedHdr, inout M meta, inout standard_metadata_t standard_metadata);
control VerifyChecksum<H, M>(in H hdr, inout M meta, inout standard_metadata_t standard_metadata);
control Ingress<H, M>(inout H hdr, inout M meta, inout standard_metadata_t standard_metadata);
control Egress<H, M>(inout H hdr, inout M meta, inout standard_metadata_t standard_metadata);
control ComputeCkecksum<H, M>(inout H hdr, inout M meta);
control Deparser<H>(packet_out b, in H hdr);
package V1Switch<H, M>(Parser<H, M> p, VerifyChecksum<H, M> vr, Ingress<H, M> ig, Egress<H, M> eg, ComputeCkecksum<H, M> ck, Deparser<H> dep);
header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<32> f4;
    bit<32> b1;
    bit<32> b2;
    bit<32> b3;
    bit<32> b4;
}

struct metadata {
}

struct headers {
    @name("data") 
    data_t data;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("start") state start {
        packet.extract(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("setb1") action setb1(bit<32> val) {
        hdr.data.b1 = val;
    }
    @name("noop") action noop() {
    }
    @name("setb3") action setb3(bit<32> val) {
        hdr.data.b3 = val;
    }
    @name("on_hit") action on_hit() {
    }
    @name("on_miss") action on_miss() {
    }
    @name("setb2") action setb2(bit<32> val) {
        hdr.data.b2 = val;
    }
    @name("setb4") action setb4(bit<32> val) {
        hdr.data.b4 = val;
    }
    @name("A1") table A1() {
        actions = {
            setb1;
            noop;
            NoAction;
        }
        key = {
            hdr.data.f1: ternary;
        }
        default_action = NoAction();
    }
    @name("A2") table A2() {
        actions = {
            setb3;
            noop;
            NoAction;
        }
        key = {
            hdr.data.b1: ternary;
        }
        default_action = NoAction();
    }
    @name("A3") table A3() {
        actions = {
            on_hit;
            on_miss;
            NoAction;
        }
        key = {
            hdr.data.f2: ternary;
        }
        default_action = NoAction();
    }
    @name("A4") table A4() {
        actions = {
            on_hit;
            on_miss;
            NoAction;
        }
        key = {
            hdr.data.f2: ternary;
        }
        default_action = NoAction();
    }
    @name("B1") table B1() {
        actions = {
            setb2;
            noop;
            NoAction;
        }
        key = {
            hdr.data.f2: ternary;
        }
        default_action = NoAction();
    }
    @name("B2") table B2() {
        actions = {
            setb4;
            noop;
            NoAction;
        }
        key = {
            hdr.data.b2: ternary;
        }
        default_action = NoAction();
    }
    apply {
        if (hdr.data.b1 == 32w0) {
            A1.apply();
            A2.apply();
            if (hdr.data.f1 == 32w0) 
                switch (A3.apply().action_run) {
                    on_hit: {
                        A4.apply();
                    }
                }

        }
        B1.apply();
        B2.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.data);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;